#encoding: utf-8

require 'rest-client'
require 'ostruct'

module ReCaptcha
  module_function

  def public_key
    "6LetNegSAAAAAIVymuOOh1TysrFfmPyd0Gpjde2D"
  end

  def verify(challenge, response, client_ip)
    result = RestClient.post "http://www.google.com/recaptcha/api/verify",
              { 
                privatekey: private_key,
                remoteip:   client_ip,
                challenge:  challenge,
                response:   response
              }

    parse_result(response)
  end

  # --- Private module methods ---
  #

  def private_key
    "6LetNegSAAAAADvemiXxD0RMKV2OTj_fnW-fOr-R"
  end

  # The response is in the following format: [true or false]\n[message]
  #
  def parse_result(result)
    result  = result.split("\n")
    success = result.first == "true"
    message = result.last

    OpenStruct.new verified?: success, message: format_message(success, message)
  end

  def format_message(success, message)
    return message if success
    
    if message == "incorrect-captcha-sol"
      "Incorrect captcha solution"
    else
      "Unkown RECAPTCHA error. Please try again."
    end
  end

  private_class_method :private_key, :parse_result, :format_message
end
