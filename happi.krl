ruleset happi {
    meta {
        use module happi_keys
        provides get_QRcode
        shares get_QRcode // share for testing, not for production
    }

    global {
        get_QRcode = function(data){
            api_key = keys:happi
            url = <<https://api.happi.dev/v1/qrcode?data=#{data}&apikey=#{api_key}>>
            response = http:get(url)
            content = response{"content"}
            decoded = content.decode()
            decoded //return decoded
        }
    }
}