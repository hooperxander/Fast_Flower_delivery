ruleset driver {
  meta {
    shares __testing
  }
  global {
    __testing = { "queries":
      [ { "name": "__testing" }
      //, { "name": "entry", "args": [ "key" ] }
      ] , "events":
      [ //{ "domain": "d1", "type": "t1" }
      //, { "domain": "d2", "type": "t2", "attrs": [ "a1", "a2" ] }
      ]
    }
  }
  rule new_order{
    select when driver new_order
    //event received from store
    //gossip the order to other drivers who dont have this order yet
    //respond with a bid to the store
  }
  rule make_delivery{
    select when driver assigned
    //event sent from store telling driver they got the delivery
    //make delivery by waiting some amount of time then scanning the QR code on customers phone
  }
  
  //then there are all the rules for the gossip protocol to ensure all drivers know about every order so they can bid
}

