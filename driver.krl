ruleset driver {
  meta {
    use module io.picolabs.subscription alias Subscriptions
    shares __testing
  }
  global {
    __testing = { "queries":
      [ { "name": "__testing" }
      ] , "events":
      [ { "domain": "driver", "type": "set_bid", "attrs": [ "bid" ] }
      ]
    }
  }

  rule update_bid{
    select when driver set_bid
    fired{
      ent:bid := event:attrs{"bid"}.defaultsTo(0)
    }
  }

  rule new_order{
    //event received from store
    select when driver new_order where not ent:orders.defaultsTo([]) >< event:attr("id")
    foreach Subscriptions:established("Tx_role", "driver") setting (sub)
    pre {
      id = event:attr("id").klog(id)
      store_eci = event:attr("store_eci")
    }
    every {
      event:send({"eci": sub{"Tx"}, "domain": "driver", "type":"new_order", "attrs": event:attrs})
      send_directive("new order")
    }
    fired {
      ent:orders := ent:orders.defaultsTo([]).append(id) on final
      raise driver event "make_bid" attributes event:attrs on final
    }
  }

  rule bid{
    select when driver make_bid
    pre{
      store_eci = event:attrs{"store_eci"}
      order_id = event:attrs{"id"}
      driver_eci = meta:eci
      bid = ent:bid.defaultsTo(0)
    }
    event:send({"eci": store_eci, "domain": "store", "type": "bid", "attrs": {"id": order_id, "eci": driver_eci, "bid": bid}})
  }
}
