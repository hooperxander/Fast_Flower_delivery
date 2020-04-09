ruleset store {
  meta {
    shares __testing, getOrders, getBids, getIP, getPreference
  }
  global {
    __testing = { "queries":
      [ { "name": "__testing" }
      , { "name": "getOrders"}
      , { "name": "getBids"}
      , { "name": "getIP"}
      , { "name": "getPreference"}
      ] , "events":
      [ { "domain": "store", "type": "reset" }
      , { "domain": "store", "type": "IP", "attrs": [ "IP" ] }
      , { "domain": "store", "type": "preferences", "attrs": [ "accept_bids" ] }
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
    //add the order with all attributes to the list of orders
    //raise store broadcast
  }
  rule broadcast_order{
    select when store broadcast
    //notify drivers who are connected by a subscription of the new order
    //schedule an assign delivery event for 30 secs
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
    //api calls are both in here to text customer a QR code
  }
  rule item_delivered{
    select when store delivery_complete
    //event received from driver
    //update orders list to reflect delivery
  }
  rule reset{
    select when store reset
    always{
      clear ent:orders
      clear ent:bids
      clear ent:IP
      clear ent:accept_bids
      ent:orders := []
      //this map keys order ids to bids from drivers
      ent:bids := {}
      ent:IP := 0
      ent:accept_bids := 0
    }
  }
}

