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
    send(SendParameters {
      to: msg.sender,
      value: 0,
      bounce: false,
      mode: SendRemainingBalance + SendIgnoreErrors
    });
  }

  receive(msg: Slice) {
    let outMsg: Cell = beginCell()
            .storeUint(0x10, 6)
            .storeAddress(self.admin)
            .storeAddress(context().sender)
            .storeCoins(0)
            .storeUint(0, 64 + 2)
            .storeRef(msg.asCell())
            .endCell();

    nativeSendMessage(outMsg, 1);
  }
}
