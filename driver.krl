ruleset driver {
  meta {
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
    select when driver new_order
    //event received from store
    //TODO: gossip the order to ALL other drivers.  Each driver will ignore deliveries it already knows about.
    //respond with a bid to the store
    fired {
      raise driver event "make_bid" attributes event:attrs
    }
  }

  rule bid{
    select when driver make_bid
    pre{
      store_eci = event:attrs{"store_eci"}
      order_id = event:attrs{"id"}
      driver_eci = meta:eci
      bid = ent:bid
    }
    event:send({"eci": store_eci, "domain": "store", "type": "bid", "attrs": {"id": order_id, "eci": driver_eci, "bid": bid}})
  }
}
