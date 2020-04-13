# Fast Flower Delivery

## Happi API
happi.krl provides the function `get_QRcode(data)` with the parameter `data` being whatever you want to encode in the QRcode, which is a sky/event url in our case.\
This function will return the following object:\
```
{
    "success": true,
    "qrcode": "data:image/png;base64,<encoding>",
    "size": {
        "width": 400,
        "height": 400
    }
}
```
With the value of `"qrcode"` being a 64bit encoded .png file, which can be displayed directly without any modifications.

To use, you need to make a file `happi_keys.krl`, which contains the following:
```
ruleset happi_keys {
    meta {
        key happi "<your API key>"
        provides keys happi to happi
    }
}
```
Remember, don't push your api keys :P\
The .gitignore will ignore any files with *key* in it's name.

## Twilio API
I modified the twilio API slightly to make it easier to use among our group.\
Just like the happi API above, you need to make a file called `twilio_keys.krl` which looks like this:
```
ruleset twilio_keys {
    meta {
        key twilio {
            "account_sid": "<your twilio account sid>",
            "auth_token": "<your twilio auth token>",
            "phone_number_from": "<your twilio phone number>" //remember to include the '+' at the beginning!
        }
        provides keys twilio to twilio
    }
}
```
If you make the file exactly as described, everything should just work.