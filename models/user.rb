#encoding: utf-8

require 'bcrypt'

class User
  include DataMapper::Resource
  include BCrypt

  property :id, Serial,
  		     key: true

  property :username, String,
  		     length: 1..30,
  		     required: true,
  		     unique: true

  property :password, BCryptHash,
           required: true

  property :email, String,
  		     required: true, 
  		     unique: true, 
  		     format: :email_address

  # Because of a bug you cannot use length validation correctly with a BCryptHashed password
  # because the validation will be run after the password is hashed. This is a workaround.  
  attr_accessor :password_confirmation
  validates_confirmation_of :password, confirm: :password_confirmation
  validates_length_of :password_confirmation, min: 16

  has n, :snippets
  has n, :comments

  def authenticate(password)
    self.password == password
  end
end
