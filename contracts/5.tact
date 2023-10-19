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

    if(context().value < ton("2.1") || self.next_item == 0) {
      self.reply(Transfer {
          queryId: msg.queryId,
          newOwner: msg.prevOwner,
          responseDestination: msg.prevOwner,
          customPayload: null,
          forwardAmount: 0,
          forwardPayload: emptySlice()
        }.toCell());
    } else {
      nativeReserve(myBalance() + ton("2") - context().value, 0);
      let luck: Int = random(0, self.next_item);
      
      if(luck == self.next_item) {
        self.reply(Transfer {
          queryId: msg.queryId,
          newOwner: msg.prevOwner,
          responseDestination: msg.prevOwner,
          customPayload: null,
          forwardAmount: 0,
          forwardPayload: emptySlice()
        }.toCell());
      } else {
        send(SendParameters{
          to: self.nfts.get(luck)!!,
          value: 0,
          mode: SendRemainingBalance,
          body: Transfer {
            queryId: msg.queryId,
            newOwner: msg.prevOwner,
            responseDestination: msg.prevOwner,
            customPayload: null,
            forwardAmount: 0,
            forwardPayload: emptySlice()
          }.toCell()
        });
        self.nfts.set(luck, sender());
      }
    }  
  }

  receive(msg: AdminWithdrawalProfit) {
    require(sender() == self.owner, "Insufficient privelegies");
    nativeReserve(ton("0.1"), 0);

    send(SendParameters{
        to: sender(),
        value: 0,
        mode: SendRemainingBalance,
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
    
    if(self.next_item >= 100) {
      repeat(100) {
        send(SendParameters{
          to: self.nfts.get(self.next_item - 1)!!,
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
        
        self.nfts.set(self.next_item - 1, null);
        self.next_item = self.next_item - 1;
      }
      send(SendParameters{
        to: myAddress(),
        value: 0,
        mode: SendRemainingBalance,
        body: AdminWithdrawalAllNFTs {
          queryId: msg.queryId
        }.toCell()
      });
    } else {
      repeat(self.next_item) {
        send(SendParameters{
          to: self.nfts.get(self.next_item - 1)!!,
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
        
        self.nfts.set(self.next_item - 1, null);
        self.next_item = self.next_item - 1;
      }
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