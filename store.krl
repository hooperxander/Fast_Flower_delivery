ruleset store {
  meta {
    shares __testing, getOrders, getBids, getIP, getPreference, getRatings, getThreshold
    use module happi
    use module twilio
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
    //init the entry in the bids map
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
    pre{
        customer_phone = ent:orders{[id, "phone"]}
        message = "Your flowers are on the way!"
        IP_address = ent:IP
        store_eci = meta:eci
        driver_eci = event:attrs{"driver_eci"} //TODO: driver eci needed!
        id = event:attrs{"id"}
        url_to_encode = IP_address + "/sky/event/" + store_eci + "/d/store/delivery_complete?id=" + id + "&eci=" + driver_eci
        res = happi:get_QRcode(url_to_encode).klog("happi response: ")
        qrcode = res{"qrcode"}.klog("qrcode: ")
    }
    every{
      twilio:send_sms(message, customer_phone)
      send_directive("https://gundulin.github.io/CS_462/Fast_Flower_Delivery/?qrcode" + qrcode)
    }
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
