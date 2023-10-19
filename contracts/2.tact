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
    self.forward(msg.sender, emptyCell(), true, null);
  }

  receive(msg: Slice) {
    self.forward(self.admin, beginCell().storeAddress(context().sender).storeRef(msg.asCell()).asCell(), true, null);
  }
}