#encoding: utf-8

class LoginAttempts
  include DataMapper::Resource

  property :ip_address, String,
  		   required: true,
  		   unique: true,
  		   key: true

  property :attempts, Integer,
  		   default: 0

  # Stores the time in seconds from 1970
  property :lock, Integer

end
