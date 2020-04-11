ruleset store {
  meta {
    shares __testing, getOrders, getBids, getIP, getPreference, getRatings
    use module happi
    use module io.picolabs.subscription alias Subscriptions
  }
  global {
    __testing = { "queries":
      [ { "name": "__testing" }
      , { "name": "getOrders"}
      , { "name": "getBids"}
      , { "name": "getIP"}
      , { "name": "getPreference"}
      , { "name": "getRatings"}
      ] , "events":
      [ { "domain": "store", "type": "reset" }
      , { "domain": "store", "type": "IP", "attrs": [ "IP" ] }
      , { "domain": "store", "type": "preferences", "attrs": [ "accept_bids" ] }
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
      ent:accept_bids := event:attrs{"accept_bids"}
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
      ent:orders{id} := {"flowers" : flowers, "address" : address, "phone" : phone, "start" : time:now(), "deliveryTime" : deliveryTime, "assigned" : false}
       //init the entry in the bids map
      ent:bids{id} := []
      //raise store broadcast
      raise store event "broadcast"
      attributes {"id": id}
      //schedule an assign delivery event for 30 secs
      schedule store event "assign_delivery" at time:add(time:now(),{"minutes" : 1})
      attributes {"id": id}
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
    //add the bid to the bids map
  }
  rule assign_delivery{
    select when store assign_delivery
    //send a driver an event telling them they got the order
    //update the orderlist to reflect the package status
    //raise notify customer
  }
  rule notify_customer{
    select when store notify_customer
    //happi:get_QRcode("hi")
    //api calls are both in here to text customer a QR code
  }
  rule item_delivered{
    select when store delivery_complete
    //event received from driver
    //update orders list to reflect delivery
    //update rating of driver
  }
  rule reset{
    select when store reset
    always{
      clear ent:orders
      clear ent:bids
      clear ent:ratings
      clear ent:IP
      clear ent:accept_bids
      ent:orders := []
      //this map keys order ids to bids from drivers
      ent:bids := {}
      ent:ratings := {}
      ent:IP := 0
      ent:accept_bids := 0
    }
  }
}
