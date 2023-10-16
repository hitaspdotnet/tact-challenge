import "@stdlib/deploy";

/*
  TASK 3 - DEX
  Create a simple jetton dex contract that trades one pair of jettons: A and B.
  The price of jettons depends on the amount of jettons that smart contract has.
  Therefore, the smart contract needs to keep track of how much jettons it has.
  
  Price for the jetton A in swap B->A should be calculated by formula "amountOfJettonAOnContract * decimal / amountOfJettonBOnContract".
  Token prices must be decimalized for accuracy, so it is the prices that must be adjusted to decimal 1e9.
  Decimals are only needed for price accuracy. It should be set as 1e9.
  So, if smart contract has 10 of jetton A and 2 of jetton B, then after sending 1 jetton B you should receive 5 of jettons A.

  Example formula for amountOfAJettonToSend in B->A swap will be
  (amountOfJettonAOnContract * decimal / amountOfJettonBOnContract) * amountOfTokenBToSwap / decimal

  If smart contract pool doesn't have enough jettons to trade,
  then it should send incoming jettons back to the user. For a clearer explanation,
  let's look at the example we described above (smart contract has 10 of jetton A and 2 of jetton B).
  If user will send 3 jettons B, smart contract should reject the message (because contract does not have 3 * 5 = 15 jettons A)
  and send 3 jettons B back to the user.

  If smart contract receives a different jetton (neither A nor B) then throw an error.

  Implement a getter that returns the number of jettons in the pool and
  one more to get the price of jetton A or jetton B.
  Getters' behavior with incorrect parameter (address other than that of jetton A or B)
  is undefined (there are no such tests).
  
  Note:
  Admin can add jettons A and B just by sending them to the smart contract (we need to add initial supply to the pool for it to be functional).
  To be exact: any jettons (A or B) received from the admin are "added". Admin can't swap.
*/

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

inline fun calc_price(balance_src: Int, balance_des: Int, decimal: Int): Int {
  let price: Int = balance_des * decimal / balance_src;
  return price;
}

inline fun calc_swap(balance_src: Int, balance_des: Int, received: Int, decimal: Int): Int {
  let swap: Int = (calc_price(balance_src, balance_des, decimal) * received) / decimal;
  return swap;
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
    let ctx: Context = context();
    require(ctx.sender == self.jettonAddressA || ctx.sender == self.jettonAddressB, "Unsupported jetton sent!");
    
    if(msg.from == self.owner) {
      if(ctx.sender == self.jettonAddressA) {
        self.aAmount = self.aAmount + msg.amount;
      } else {
        self.bAmount = self.bAmount + msg.amount;
      }
      return;
    }

    let received: Int = msg.amount;
    let address_src: Address = self.jettonAddressA;
    let address_des: Address = self.jettonAddressB;
    let balance_src: Int = self.aAmount;
    let balance_des: Int = self.bAmount;

    if(ctx.sender == self.jettonAddressB) {
      address_src = self.jettonAddressB;
      address_des = self.jettonAddressA;
      balance_src = self.bAmount;
      balance_des = self.aAmount;
    }

    let swap: Int = calc_swap(balance_src, balance_des, received, self.decimal);

    if (balance_des < swap) {
      send(SendParameters{
        to: address_src,
        value: 0,
        mode: SendRemainingValue,
        body: TokenTransfer {
          queryId: msg.queryId,
          amount: received,
          destination: msg.from, 
          responseDestination: myAddress(), 
          customPayload: null,
          forwardTonAmount: ton("0.05"), 
          forwardPayload: msg.forwardPayload
        }.toCell()
      });
    } else {
      if(address_src == self.jettonAddressA) {
        self.aAmount = self.aAmount + received;
        self.bAmount = self.bAmount - swap;
      } else {
        self.bAmount = self.bAmount + received;
        self.aAmount = self.aAmount - swap;
      }

      send(SendParameters{
        to: address_des,
        value: 0,
        mode: SendRemainingValue,
        body: TokenTransfer {
          queryId: msg.queryId,
          amount: swap,
          destination: msg.from, 
          responseDestination: myAddress(), 
          customPayload: null,
          forwardTonAmount: ton("0.05"), 
          forwardPayload: msg.forwardPayload
        }.toCell()
      });
    }
  }

  get fun price(jetton: Address): Int { 
    if(jetton == self.jettonAddressA) {
      return calc_price(self.aAmount, self.bAmount, self.decimal);
    }

    if(jetton == self.jettonAddressB) {
      return calc_price(self.bAmount, self.aAmount, self.decimal);
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