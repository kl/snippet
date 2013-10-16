#encoding: utf-8

require 'bundler'
Bundler.require
require 'sinatra/flash'
require 'sinatra/reloader' if development?
require 'webrick'
require 'webrick/https'
require 'openssl'
require './recaptcha.rb'
require './helpers.rb'
Dir[File.dirname(__FILE__) + '/{models,config,formatters}/*.rb'].each { |file| require file }

not_found do
  "404 Page not found."
end

get "/styles.css" do
  scss :styles
end

get "/" do
  redirect "/snippets"
end

get "/login" do
  slim :login
end

post "/login" do

  if login_locked?
    flash[:error] = login_locked_message
    redirect "/login"
  end

  warden.authenticate!

  reset_login_state
  flash[:success] = "Successfully logged in"
  redirect "/"
end

get "/logout" do
  warden.logout
  flash[:success] = "Successfully logged out"
  redirect "/"
end

get "/register" do
  @captcha_public_key = ReCaptcha.public_key

  # These attributes are set if this registration is a retry
  @username = session[:fail_username] || ""
  @email    = session[:fail_email]    || ""
  @phone    = session[:fail_phone]    || ""

  delete_registration_params
  slim :register
end

post "/register" do
  user = new_user(params)

  captcha = ReCaptcha.verify params["recaptcha_challenge_field"],
                             params["recaptcha_response_field"],
                             request.ip

  if user.valid? && captcha.verified?
    user.save
    flash[:success] = "Registration successful"
    redirect "/login"
  else
    flash[:error] = format_errors(user.errors, captcha.message)
    save_registration_params(params) 
    redirect "/register"
  end
end

post "/unauthenticated" do
  attempted = env["warden.options"][:attempted_path]

  flash[:error] = unauthorized_message_for(attempted) || "You must log in first."
  redirect unauthorized_redirect_for(attempted)       || "/login"
end

get "/snippets" do
  @snippets = Snippet.all(order: [:id.desc])
  slim :snippets
end

get "/snippet/new" do
  warden.authenticate!
  slim :new_snippet
end

post "/snippet/new" do
  warden.authenticate!

  snippet = Snippet.new user_id: current_user.id,
                        title: params["name"],
                        text: params["snippet"],
                        type: params["type"]

  if snippet.save
    flash[:success] = "Snippet created successfully"
    redirect "/snippet/#{snippet.id}"
  else
    flash[:error] = format_errors(snippet.errors)
    redirect "/snippet/new"
  end
end

get "/snippet/:id" do
  @snippet = Snippet.get(params[:id]) || halt(404)
  formatter = get_formatter(@snippet.type)
  @text = formatter.format(escape_html(@snippet.text))
  
  slim :view_snippet
end

get "/snippet/:id/plain" do
  snippet = Snippet.get(params[:id]) || halt(404)
  content_type "text/plain"
  snippet.text
end

post "/snippet/:id/comment/new" do
  warden.authenticate!

  snippet_id = params[:id] 
  halt(404) unless Snippet.get(snippet_id)

  comment = Comment.new user_id:    current_user.id,
                        snippet_id: snippet_id,
                        text:       params[:comment]
  if comment.save
    redirect "/snippet/#{snippet_id}"
  else
    flash[:error] = format_errors(comment.errors)
    redirect "/snippet/#{snippet_id}"
  end
end


#
# Start the WEBrick server in HTTPS mode
#

Rack::Handler::WEBrick.run Sinatra::Application, {
  Port:               8443,
  Logger:             WEBrick::Log::new($stderr, WEBrick::Log::DEBUG),
  DocumentRoot:       settings.root,
  SSLEnable:          true,
  SSLVerifyClient:    OpenSSL::SSL::VERIFY_NONE,
  SSLCertificate:     OpenSSL::X509::Certificate.new(File.open(settings.cert_path).read),
  SSLPrivateKey:      OpenSSL::PKey::RSA.new(File.open(settings.cert_key_path).read),
  SSLCertName:        [["CN", WEBrick::Utils::getservername ]]
}
