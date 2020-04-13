ruleset store {
  meta {
    shares __testing, getOrders, getBids, getIP, getPreference, getRatings, getThreshold
    use module happi
    use module io.picolabs.subscription alias Subscriptions
    use module twilio

  }
  global {
    __testing = { "queries":
      [ { "name": "__testing" }
      , { "name": "getOrders"}
      , { "name": "getBids"}
      , { "name": "getIP"}
      , { "name": "getPreference"}
      , { "name": "getRatings"}
      , { "name": "getThreshold"}
      ] , "events":
      [ { "domain": "store", "type": "reset" }
      , { "domain": "store", "type": "IP", "attrs": [ "IP" ] }
      , { "domain": "store", "type": "preferences", "attrs": [ "accept_bids", "rank_threshold" ] }
      , { "domain": "store", "type": "new_order", "attrs": [ "id", "flowers", "address", "deliveryTime", "phone" ] }
      ]
    }
    getOrders = function(){
      return ent:orders
    }
    getBids = function(){
      return ent:bids
    }
    getIP = function(){
      return ent:IP
    }
    getThreshold = function(){
      return ent:rank_threshold
    }
    getPreference = function(){
      return ent:accept_bids
    }
    getRatings = function(){
      return ent:ratings
    }
  }
  rule set_IP{
    select when store IP
    //used so store knows what info to put on the QR code
    always{
      ent:IP := event:attrs{"IP"}
    }
  }
  rule set_pref{
    select when store preferences
    //used so store knows what info to put on the QR code
    always{
      ent:accept_bids := event:attrs{"accept_bids"}.as("Number")
      ent:rank_threshold := event:attrs{"rank_threshold"}.as("Number")
    }
  }
  rule new_order{
    select when store new_order
    pre{
      id = event:attrs{"id"}
      flowers = event:attrs{"flowers"}
      address = event:attrs{"address"}
      deliveryTime = event:attrs{"deliveryTime"}
      phone = event:attrs{"phone"}
    }
    always{
      //add the order with all attributes to the list of orders
      ent:orders{id} := {"flowers" : flowers, "address" : address, "phone" : phone, "start" : time:now(), "deliveryTime" : deliveryTime, "status" : "new"}
       //init the entry in the bids map
      ent:bids{id} := []
      //raise store broadcast
      raise store event "broadcast"
      attributes {"id": id}
      if ent:accept_bids
      //schedule an assign delivery event for 30 secs
      schedule store event "assign_delivery" at time:add(time:now(),{"minutes" : 1})
      attributes {"id": id}
      if ent:accept_bids
      //assign if not wanting bids
      raise store event "assign_delivery"
      attributes {"id": id}
      if ent:accept_bids == 0
    }
  }
  rule broadcast_order{
    select when store broadcast
    //notify drivers who are connected by a subscription of the new order
    foreach Subscriptions:established("Tx_role","driver") setting (eci)
    pre{
      id = event:attrs{"id"}
    }
    event:send({"eci":eci{"Tx"}, "domain":"driver", "type":"new_order", "attrs":{"id": id}})
  }
  rule receive_bid{
    select when store bid
    pre{
      id = event:attrs{"id"}
      driver = event:attrs{"eci"}
      bid = event:attrs{"bid"}
    }
    //add the bid to the bids map
    always{
      ent:bids{[id, driver]} := bid.defaultsTo(0)
    }
  }
  rule assign_delivery{
    select when store assign_delivery
    pre{
      id = event:attrs{"id"}
      drivers = ent:bids{event:attrs{"id"}}.keys().length() => ent:bids{event:attrs{"id"}}.keys() | ent:ratings.keys().klog("all drivers")
      valid_drivers = drivers.filter(function(a) {ent:ratings{a} >= ent:rank_threshold}).klog("valid drivers")
      driver = valid_drivers.length() => valid_drivers[0] | -1
      test = driver.klog("assigned driver")
    }
    if driver > -1 then 
    //send a driver an event telling them they got the order
    event:send({"eci":driver, "domain":"driver", "type":"assigned", "attrs":{"id": id}})
    fired{
      //update the orderlist to reflect the package status
      ent:orders{[id, "status"]} := "on its way"
      //raise notify customer
      raise store event "notify_customer"
      attributes {"id": id, "driver_eci": driver}
    }
  }
  rule notify_customer{
    select when store notify_customer
    //api calls are both in here to text customer a QR code
    pre{
        id = event:attrs{"id"}
        customer_phone = ent:orders{[id, "phone"]}
        message = "Your "+ ent:orders{[id, "flowers"]} + " are on the way!"
        IP_address = ent:IP
        store_eci = meta:eci
        driver_eci = event:attrs{"driver_eci"}
        url_to_encode = IP_address + "/sky/event/" + store_eci + "/d/store/delivery_complete?id=" + id + "&eci=" + driver_eci
        res = happi:get_QRcode(url_to_encode)
        qrcode = res{"qrcode"}
        view_qrcode = "https://gundulin.github.io/CS_462/Fast_Flower_Delivery/?qrcode=" + qrcode
        print = url_to_encode.klog("event url: ")
        print2 = view_qrcode.klog("qrcode url: ")
    }
    every{
      twilio:send_sms(message, customer_phone)
      send_directive(view_qrcode)
    }
  }
  rule item_delivered{
    select when store delivery_complete
    pre{
      id = event:attrs{"id"}
      driver = event:attrs{"eci"}
      started = ent:orders{[id, "start"]}
      delivered = time:add(time:now(),{"minutes" : ent:orders{[id, deliveryTime]}})
    }
    //event received from driver
    always{
      //update orders list to reflect delivery
      ent:orders{[id, "status"]} := "delivered"
      //update rating of driver
      //time:compare has not been implemented in the new pico engine
      //so for now, all drivers get +1 just for making the dilivery.
      ent:ratings{driver} := ent:ratings{driver} + 1
      // ent:ratings{driver} := ent:ratings{driver} + 1
      // if time:compare(delivered, started)
      // ent:ratings{driver} := ent:ratings{driver} - 1
      // if time:compare(started, delivered)
    }
  }
  rule reset{
    select when store reset
    always{
      clear ent:orders
      clear ent:bids
      clear ent:ratings
      clear ent:IP
      clear ent:accept_bids
      clear ent:rank_threshold
      ent:orders := []
      //this map keys order ids to bids from drivers
      ent:bids := {}
      ent:ratings := Subscriptions:established("Tx_role","driver").collect(function(x){ x{"Tx"} }).map(function(v,k){0})
      ent:IP := 0
      ent:accept_bids := 0
      ent:rank_threshold := -100
    }
  }
}
