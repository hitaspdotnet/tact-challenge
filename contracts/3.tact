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
    let sender: Address = sender();
    require(sender == self.jettonAddressA || sender == self.jettonAddressB, "Unsupported jetton sent!");
   
    if(msg.from != self.owner) {
      let amount: Int = msg.amount;
      if(sender == self.jettonAddressA) {
        if(amount > self.aAmount){
          send(SendParameters {
              to: self.jettonAddressA,
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
          return;
        } else {
          amount = (self.bAmount * self.decimal / self.aAmount) * msg.amount / self.decimal;
          send(SendParameters {
              to: self.jettonAddressB,
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

          self.aAmount = self.aAmount + msg.amount;
          self.bAmount = self.bAmount - amount;
          return;
        }
      } else {
        if(amount > self.bAmount){
          send(SendParameters {
              to: self.jettonAddressB,
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
          return;
        } else {
          amount = (self.aAmount * self.decimal / self.bAmount) * msg.amount / self.decimal;
          send(SendParameters {
              to: self.jettonAddressA,
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
         
          self.bAmount = self.bAmount + msg.amount;
          self.aAmount = self.aAmount - amount;
          return;
        }
      }
    } else {
      if(sender == self.jettonAddressA) {
        self.aAmount = self.aAmount + msg.amount;
      } else {
        self.bAmount = self.bAmount + msg.amount;
      }
    }
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