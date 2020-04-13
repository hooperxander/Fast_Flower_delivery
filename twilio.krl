ruleset twilio {
    meta {
        use module twilio_keys
        provides send_sms
        shares send_sms
    }

    global {
        send_sms = defaction(message, to, from = keys:twilio{"phone_number_from"}) {
            account_sid = keys:twilio{"account_sid"}
            auth_token = keys:twilio{"auth_token"}
            base_url = <<https://#{account_sid}:#{auth_token}@api.twilio.com/2010-04-01/Accounts/#{account_sid}/>>
            http:post(base_url + "Messages.json", form = {
                "From":from,
                "To":to,
                "Body":message
            })
        }
    }
}