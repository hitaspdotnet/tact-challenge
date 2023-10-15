import "@stdlib/deploy";

/*
  TASK 3 - DEX
  Create a simple jetton dex contract that trades one pair of jettons: A and B.
  The price of jettons depends on the amount of jettons that smart contract has.
  Therefore, the smart contract needs to keep track of how much jettons it has.
  
  Price for the jetton A in swap B->A should be calculated by formula "amountOfJettonAOnContract * decimal / amountOfJettonBOnContract".
  Decimals are only needed for price accuracy. It should be set as 1e9.
  So, if smart contract has 10 of jetton A and 2 of jetton B, then after sending 1 jetton B you should receive 5 of jettons A.

  If smart contract pool doesn't have enough jettons to trade
  (for example someone sends 99999 jettons of B, but dex pool only has 10 of jettons A),
  then sent incoming jettons (B, in our example) back to the sender.

  If smart contract receives a different jetton (neither A nor B) then throw an error.

  Implement a getter that returns the number of jettons in the pool and
  one more to get the price of jetton A or jetton B.
  Getters' behavior with incorrect parameter (address other than that of jetton A or B)
  is undefined (there are no such tests).
  
  Note:
  Admin can add jettons A and B just by sending them to the smart contract (we need to add initial supply to the pool for it to be functional).
  To be exact: any jettons (A or B) received from the admin are "added". Admin can't swap.
*/

message(0x7362d09c) JettonNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forwardPayload: Slice as remaining;
}

message(0xf8a7ea5) JettonTransfer {
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
  aAmount: Int = 0;
  bAmount: Int = 0;
  jettonAddressA: Address;
  jettonAddressB: Address;
  decimal: Int = 1000000000;

  init(admin: Address, newJettonAddressA: Address, newJettonAddressB: Address) {
    self.owner = admin;
    self.jettonAddressA = newJettonAddressA;
    self.jettonAddressB = newJettonAddressB;
  }

  fun calc_price(jetton_src: Int, jetton_dst: Int): Int {
    let jetton_price: Int = (jetton_src * self.decimal) / jetton_dst;
    return jetton_price;
  }

  fun calc_swap(jetton_src: Int, jetton_dst: Int, received: Int): Int {
    let swap: Int = received / self.calc_price(jetton_src, jetton_dst);
    return swap;
  }

  fun transferTo(jetton_wallet: Address, destination: Address, amount: Int, query_id: Int) {
    if (amount > 0) {
      send(SendParameters{
        to: jetton_wallet,
        value: 0,
        mode: SendRemainingValue,
        body: JettonTransfer {
          queryId: query_id,
          amount: amount,
          destination: destination, 
          responseDestination: destination, 
          customPayload: null,
          forwardTonAmount: ton("0.000001"), 
          forwardPayload: emptySlice()
        }.toCell()
      });
    }
  }

  receive(msg: JettonNotification) {
    let ctx: Context = context();
    require(msg.from == self.jettonAddressA || msg.from == self.jettonAddressB, "Unsupported jetton sent!");
    if(ctx.sender == self.owner) {
      if(msg.from == self.jettonAddressA) {
        self.aAmount = self.aAmount + msg.amount;
      } else {
        self.bAmount = self.bAmount + msg.amount;
      }
    } else {
      let received: Int = msg.amount;
      let address_src: Address = self.jettonAddressA;
      let address_dst: Address = self.jettonAddressB;
      let balance_src: Int = 0;
      let balance_dst: Int = 0;
      if(msg.from == self.jettonAddressA) {
        balance_src = self.aAmount;
        balance_dst = self.bAmount;
      } else {
        address_src = self.jettonAddressB;
        address_dst = self.jettonAddressA;
        balance_src = self.bAmount;
        balance_dst = self.aAmount;
      }

      let swap: Int = self.calc_swap(balance_src, balance_dst, received);
      if (swap >= balance_dst) {
        self.transferTo(ctx.sender, address_src, received, msg.queryId);
      } else {
        self.transferTo(ctx.sender, address_dst, swap, msg.queryId);

        if(address_src == self.jettonAddressA) {
          self.aAmount = self.aAmount + received;
          self.bAmount = self.bAmount - swap;
        } else {
          self.bAmount = self.bAmount + received;
          self.aAmount = self.aAmount - swap;
        }
      }
    }
  }

  get fun price(jetton: Address): Int { 
    if(jetton == self.jettonAddressA) {
      return self.calc_price(self.aAmount, self.bAmount);
    }

    if(jetton == self.jettonAddressB) {
      return self.calc_price(self.bAmount, self.aAmount);
    }
  }
  
  get fun balance(jetton: Address): Int { 
    if(jetton == self.jettonAddressA) {
      return self.aAmount;
    }
    
    if(jetton == self.jettonAddressB) {
      return self.bAmount;
    }
  }
}