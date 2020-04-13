ruleset driver {
  meta {
    shares __testing, order_history, has_order
    use module io.picolabs.subscription alias Subscriptions
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
    
    order_history = function() {
      return ent:orders.defaultsTo([])
    }
    
    has_order = function(id) {
      return ent:order.defaultsTo([]).any(id)
    }
    
  }
  rule new_order{
    select when driver new_order
    //event received from store
    pre {
      id = event:attrs{"id"}
      have = ent:order.any(id)
      fire_away = ent:neighbors
    }
    
    fired {
      ent:orders := (have) => ent:orders | ent:orders.defaultsTo([]).append(id)
      raise driver event "gossip"
        attributes {
          "id": id.as("Number")
        }
    }
    //gossip the order to other drivers who dont have this order yet
    

    
  }
    //respond with a bid to the store
  rule make_delivery{
    select when driver assigned
    //event sent from store telling driver they got the delivery
    //make delivery by waiting some amount of time then scanning the QR code on customers phone
  }
  
  //then there are all the rules for the gossip protocol to ensure all drivers know about every order so they can bid
  rule gossip_order {
    select when driver gossip
        foreach Subscriptions:established("Tx_role","driver") setting (eci)
    pre{
      id = event:attr("id").klog("id: ")
      host = "http://localhost:8080"
      chan = eci{"Tx"}
      url = host + "/sky/cloud/" + chan + "/driver/has_order?id=" + id.as("Number")
      response = http:get(url, "")
      answer = response{"content"}.decode().klog("answer: ")
    }
    if not answer then event:send({"eci":eci{"Tx"}, "domain":"driver", "type":"new_order", "attrs":{"id": id}})
    fired {
      ent:neighbors := ent:neighbors.defaultsTo({}).put(eci{"Tx"}, id)
    }
  }
}

