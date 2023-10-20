import "@stdlib/deploy";

message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forwardPayload: Slice as remaining;
}

message(0xf8a7ea5) TokenTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address?;
    customPayload: Cell?;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}


contract Task3 with Deployable {
  owner: Address;
  aAmount: Int;
  bAmount: Int;
  jettonAddressA: Address;
  jettonAddressB: Address;
  decimal: Int;

  init(admin: Address, newJettonAddressA: Address, newJettonAddressB: Address) {
    self.owner = admin;
    self.jettonAddressA = newJettonAddressA;
    self.jettonAddressB = newJettonAddressB;
    self.aAmount = 0;
    self.bAmount = 0;
    self.decimal = 1000000000;
  }

  receive(msg: TokenNotification) {
    require(sender() == self.jettonAddressA || sender() == self.jettonAddressB, "Unsupported jetton sent!");

    let amount: Int = msg.amount;
    let dest: Address = self.jettonAddressA;
    
    if(sender() == self.jettonAddressA) {
      if(msg.from == self.owner) {
        self.aAmount = self.aAmount + msg.amount;
        return;
      } 
      
      if(amount <= self.aAmount){
        amount = (self.bAmount * self.decimal / self.aAmount) * msg.amount / self.decimal;
        dest = self.jettonAddressB;
        self.aAmount = self.aAmount + msg.amount;
        self.bAmount = self.bAmount - amount;
      }

    } else {
      if(msg.from == self.owner) {
        self.bAmount = self.bAmount + msg.amount;
        return;
      } 
      
      if(amount <= self.bAmount){
        amount = (self.aAmount * self.decimal / self.bAmount) * msg.amount / self.decimal;
        dest = self.jettonAddressA;
        self.bAmount = self.bAmount + msg.amount;
        self.aAmount = self.aAmount - amount;
      }
    }
    
    send(SendParameters {
          to: dest,
          value: 0,
          bounce:false,
          mode: SendRemainingValue,
          body: TokenTransfer { 
            queryId: 0,
            amount: amount,
            destination: msg.from,
            responseDestination: myAddress(),
            customPayload: null,
            forwardTonAmount: ton("0.01"),
            forwardPayload: emptySlice()
          }.toCell()
        });
  }

  get fun price(jetton: Address): Int { 
    if(jetton == self.jettonAddressA) {
      return self.bAmount * self.decimal / self.aAmount;
    }

    if(jetton == self.jettonAddressB) {
      return self.aAmount * self.decimal / self.bAmount;
    }
    return 0;
  }
  
  get fun balance(jetton: Address): Int { 
    if(jetton == self.jettonAddressA) {
      return self.aAmount;
    }
    
    if(jetton == self.jettonAddressB) {
      return self.bAmount;
    }
    return 0;
  }
}