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
with the value of `"qrcode"` being a 64bit encoded .png file, which can be displayed directly without any modifications.

To use, you need to make your own file called `happi_keys.krl`, which contains the following:
```
ruleset happi_keys {
    meta {
        key happi "<your API key>"
        provides keys happi to happi
    }
}
```
The .gitignore will ignore any files with *key* in it's name.\
Remember, don't push your api keys :P
