import "@stdlib/deploy";

message AdminWithdrawalProfit {
  queryId: Int as uint64;
}

message AdminWithdrawalAllNFTs {
  queryId: Int as uint64;
}

message AdminFetchProfit {
  queryId: Int as uint64;
}

message(0x05138d91) OwnershipAssigned {
    queryId: Int as uint64;
    prevOwner: Address;
    forwardPayload: Slice as remaining; 
}

message(0x5fcc3d14) Transfer { 
    queryId: Int as uint64;            
    newOwner: Address; 
    responseDestination: Address; 
    customPayload: Cell?; 
    forwardAmount: Int as coins; 
    forwardPayload: Slice as remaining; 
}

contract Task5 with Deployable {
  seed: Int as uint128;
  owner: Address;
  nfts: map<Int as uint16, Address>;
  next_item: Int as uint16 = 0;
  
  init(seed: Int, owner: Address) {
    self.owner = owner;
    self.seed = seed; // needed to deploy multiple smart contracts copies from one admin address
  }

  receive(msg: OwnershipAssigned) {
    if(msg.prevOwner == self.owner) {
      self.nfts.set(self.next_item, sender());
      self.next_item = self.next_item + 1;
      return;
    }

    let swap: Bool = context().value - ton("2.1") >= 0;
    let refund: Bool = context().value - ton("0.1") > 0;

    if((!swap && refund) || self.next_item == 0) {
      send(SendParameters{
        to: sender(),
        value: 0,
        mode: SendRemainingValue,
        body: Transfer {
          queryId: msg.queryId,
          newOwner: msg.prevOwner,
          responseDestination: msg.prevOwner,
          customPayload: null,
          forwardAmount: 0,
          forwardPayload: emptySlice()
        }.toCell()
      });
    } else {
     
      let luck: Int = random(0, self.next_item);
      let value: Int = context().value - ton("2");
      if(luck == self.next_item) {
        send(SendParameters{
          to: sender(),
          value: value,
          mode: SendPayGasSeparately,
          body: Transfer {
            queryId: msg.queryId,
            newOwner: msg.prevOwner,
            responseDestination: msg.prevOwner,
            customPayload: null,
            forwardAmount: 0,
            forwardPayload: emptySlice()
          }.toCell()
        });
        return;
      }

      let swapItemAddress: Address = self.nfts.get(luck)!!;
      self.nfts.set(luck, sender());
      
      send(SendParameters{
        to: swapItemAddress,
        value: value,
        mode: SendPayGasSeparately,
        body: Transfer {
          queryId: msg.queryId,
          newOwner: msg.prevOwner,
          responseDestination: msg.prevOwner,
          customPayload: null,
          forwardAmount: 0,
          forwardPayload: emptySlice()
        }.toCell()
      });
    }  
  }

  receive(msg: AdminWithdrawalProfit) {
    require(sender() == self.owner, "Insufficient privelegies");
    
    send(SendParameters{
        to: sender(),
        value: myBalance() - context().value - ton("0.1"),
        mode: SendRemainingValue + SendIgnoreErrors,
        body: AdminFetchProfit {
          queryId: msg.queryId
        }.toCell()
    });
  }

  receive(msg: AdminWithdrawalAllNFTs) {
    if(sender() != myAddress()) {
      require(context().value - (ton("1") + self.next_item * ton("0.08")) >= 0, "Insufficent funds");
    }

    require(sender() == self.owner || sender() == myAddress(), "Invalid sender");

    let i: Int = 0;
    let n: Int = self.next_item - 1;
    
    while(i < 100 && n >= 0) {
      send(SendParameters{
        to: self.nfts.get(n)!!,
        value: ton("0.08"),
        mode: SendPayGasSeparately,
        body: Transfer {
          queryId: msg.queryId,
          newOwner: self.owner,
          responseDestination: self.owner,
          customPayload: null,
          forwardAmount: 0,
          forwardPayload: emptySlice()
        }.toCell()
      });
      
      self.nfts.set(n, null);
      self.next_item = n;
      
      i = i + 1;
      n = n - 1;
    } 

    if(self.next_item > 0){
      send(SendParameters{
        to: myAddress(),
        value: 0,
        mode: SendRemainingBalance,
        body: AdminWithdrawalAllNFTs {
          queryId: msg.queryId
        }.toCell()
      });
    }
  }

  get fun profit(): Int {
    if(myBalance() > ton("0.1")) {
      return myBalance() - ton("0.1");
    }
    return 0;
  }
  
  get fun nfts(): map<Int as uint16, Address> { 
    if(self.next_item == 0) {
      return emptyMap();
    }
    return self.nfts;
  }
}