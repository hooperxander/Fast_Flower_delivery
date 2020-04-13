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
      [ { "domain": "driver", "type": "new_order", "attrs": {"id": 0, "store_eci": ""}}
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
      store_eci = event:attr("Rx").klog("store eci: ")
      id = event:attr("id").klog("id: ")
      have = ent:orders.any(id).klog("have: ")
      total_neighbors = Subscriptions:established("Tx_role", "driver")
        .length().defaultsTo(0).klog("Total neighbors: ")
      neighbors_with_order = ent:neighbors.get(id).length().defaultsTo(0).klog("neighbors w/ order: ")
      fire_away = (total_neighbors > neighbors_with_orders).klog("fire_away: ")
    }
    send_directive("new_order", {"order_id": id, "sent": fire_away})
    
    fired {
      ent:orders := (have) => ent:orders | ent:orders.defaultsTo([]).append(id)
      //gossip the order to other drivers who dont have this order yet
      raise driver event "gossip"
        attributes {
          "id": id
        } if fire_away
    }
    
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
        // host = "http://localhost:8080"
        // chan = eci{"Tx"}
        // url = host + "/sky/cloud/" + chan + "/driver/has_order?id=" + id.as("Number")
        // response = http:get(url, "")
        // answer = response{"content"}.decode().klog("answer: ")
      }
      
      /*if not answer then */event:send({"eci":eci{"Tx"}, "domain":"driver", "type":"new_order", "attrs":{"id": id}})
      fired {
        
        neighbor = ent:neighbors.get(id).defaultsTo([])
        in = neighbor.append(eci{"Tx"})
        ent:neighbors := ent:neighbors.defaultsTo({}).put(id, in)
      }
      
  }
}

