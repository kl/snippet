#encoding: utf-8

require 'bundler'
Bundler.require
require 'sinatra/flash'
require 'sinatra/reloader' if development?

require './recaptcha.rb'
require './helpers.rb'
require './models/user.rb'
require './models/snippet.rb'
require './models/comment.rb'
require './config/warden_config.rb'

class SnippetApp < Sinatra::Base

  register Sinatra::Reloader
  register Sinatra::Flash
  helpers AppHelper

  DataMapper.setup(:default, "sqlite://#{settings.root}/database.db")
  DataMapper.finalize
  DataMapper.auto_upgrade!

  get "/styles.css" do
    scss :styles
  end

  get "/" do
    slim :index
  end

  get "/login" do
    slim :login
  end

  post "/login" do
    env["warden"].authenticate!

    flash[:success] = "Successfully logged in"

    redirect "/"
  end

  get "/register" do
    @captcha_public_key = ReCaptcha.public_key
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
      redirect "/"
    else
      flash[:error] = format_errors(user.errors, captcha.message)
      redirect "/register"
    end
  end

  get "/logout" do
    puts env["warden"].raw_session.inspect
    env["warden"].logout
    flash.success = "Successfully logged out"
    redirect "/"
  end

  post "/unauthenticated" do
    session[:return_to] = env["warden.options"][:attempted_path]
    puts env["warden.options"][:attempted_path]
    #flash.error = env["warden"].message || "You must log in"
    redirect "/login"
  end

  get "/snippet" do
    @snippets = Snippet.all(order: [:id.desc])
    #binding.pry
    slim :snippets
  end

  get "/snippet/new" do
    env["warden"].authenticate!
    slim :new_snippet
  end

  post "/snippet/new" do
    snippet = Snippet.new(user_id: current_user.id, title: params["name"], text: params["snippet"])

    if snippet.save
      flash[:success] = "Snippet created successfully"
      redirect "/snippet/#{snippet.id}"
    else
      flash[:error] = snippet.errors.as_list
      redirect "/snippet/new"
    end
  end

  get "/snippet/:id" do
    @snippet = Snippet.get(params[:id].to_i)
    slim :view_snippet
  end

  post "/snippet/:id/comment/new" do
    snippet_id = params[:id].to_i
    comment = Comment.new(user_id: current_user.id, snippet_id: snippet_id, text: params[:comment])

    if comment.save
      redirect "/snippet/#{snippet_id}"
    else
      flash[:error] = comment.errors.as_list
      redirect "/snippet/#{snippet_id}"
    end
  end

end
