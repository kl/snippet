#encoding: utf-8

class Comment
  include DataMapper::Resource

  property :id, Serial, key: true
  property :text, Text, required: true

  belongs_to :snippet
  belongs_to :user
end
