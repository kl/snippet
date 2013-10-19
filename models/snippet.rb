#encoding: utf-8

require 'dm-timestamps'

class Snippet
  include DataMapper::Resource

  property :id, Serial, key: true
  property :title, String, length: 60, required: true
  property :text, Text, required: true
  property :type, String, required: true

  # These two properties are automatically added by DM
  property :created_at, DateTime
  property :updated_at, DateTime

  belongs_to :user
  has n, :comments
end
