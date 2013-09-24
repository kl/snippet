#encoding: utf-8

class Snippet
  include DataMapper::Resource

  property :id, Serial, key: true
  property :title, String, length: 256
  property :text, Text, required: true

  belongs_to :user
  has n, :comments
end
