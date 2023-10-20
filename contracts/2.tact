import "@stdlib/deploy";

message(0x44) Refund {
  queryId: Int as uint64;
  sender: Address;
}

contract Task2 with Deployable {
  admin: Address;

  init(admin: Address) {
    self.admin = admin;
  }
  
  receive(msg: Refund) {
    require(context().sender == self.admin, "Invalid sender");
    nativeSendMessage(beginCell()
            .storeUint(0x18, 6)
            .storeAddress(msg.sender)
            .storeCoins(0)
            .storeUint(1, 1 + 4 + 4 + 64 + 32 + 1 + 1)
            .endCell(), 64);
    // send(SendParameters {
    //   to: msg.sender,
    //   value: 0,
    //   bounce: false,
    //   mode: SendRemainingBalance + SendIgnoreErrors
    // });
  }

  receive(msg: Slice) {

    nativeSendMessage(beginCell()
            .storeUint(0x18, 6)
            .storeAddress(self.admin)
            .storeCoins(0)
            .storeUint(1, 1 + 4 + 4 + 64 + 32 + 1 + 1)
            .storeRef(beginCell().storeAddress(context().sender).storeRef(msg.asCell()).endCell())
            .endCell(), 64);
  }
}