#encoding: utf-8

configure do
  helpers AppHelper

  use Rack::Session::Cookie, secret: "nothingissecretontheinternet"

  use Warden::Manager do |config|

    config.serialize_into_session { |user| user.id }

    config.serialize_from_session { |id| User.get(id) }

    config.scope_defaults :default, strategies: [:password], action: "/unauthenticated"

    config.failure_app = Sinatra::Application
  end

  DataMapper.setup(:default, "sqlite://#{settings.root}/database.db")
  DataMapper.finalize
  DataMapper.auto_upgrade!
end