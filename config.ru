require 'rack'
require './app'

builder = Rack::Builder.new do

  use Rack::Session::Cookie, secret: "nothingissecretontheinternet"
  #use Rack::Flash, accessorize: [:error, :success]

  use Warden::Manager do |config|

    config.serialize_into_session { |user| user.id }

    config.serialize_from_session { |id| User.get(id) }

    config.scope_defaults :default, strategies: [:password], action: "/unauthenticated"

    config.failure_app = SnippetApp
  end

  run SnippetApp
end

Rack::Handler::WEBrick.run builder, :Port => 4567
