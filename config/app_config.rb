#encoding: utf-8

configure do
  helpers AppHelper
  helpers LoginHelper

  #
  # Configures the cookie based sessions.
  # -------------------------------------
  # The session will expire after 20 minutes of non-activity.
  # and the HttpOnly and Secure headers are set. HttpOnly ensures that the cookie is only
  # accessible through HTTP, and not through DOM scripting. Secure ensures that the cookie
  # is always sent over HTTPS. The key: option specifies cookie key name on the user's browser,
  # and the secret: option is used to hash the session id.
  # Sessions are renewed after the user successfully logs in as a countermeasure against
  # session fixation. See post "/login" in app.rb
  #

  use Rack::Session::Cookie, key:           "id",
                             expire_after:  60 * 20,
                             secret:        SecureRandom.hex(32),
                             http_only:     true,
                             secure:        true

  set :environment, :production

  set :cert_root,     File.join(settings.root, "ssl")
  set :cert_key_path, File.join(settings.cert_root, "snippet.cert.key")
  set :cert_path,     File.join(settings.cert_root, "snippet.cert.crt")

  use Warden::Manager do |config|

    config.serialize_into_session { |user| user.id }
    config.serialize_from_session { |id|   User.get(id) }

    config.scope_defaults :default, strategies: [:password], action: "/unauthenticated"
    config.failure_app = Sinatra::Application
  end

  DataMapper.setup(:default, "sqlite://#{settings.root}/database.db")
  DataMapper.finalize
  DataMapper.auto_upgrade!
  #DataMapper::Model.raise_on_save_failure = true
end
