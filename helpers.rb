#encoding: utf-8

module AppHelper

  UNAUTHORIZED = {
    "/snippet/new"               => { message: "You must log in before posting a snippet.", redirect: "/login" },
    %r{/snippet/\d+/comment/new} => { message: "You must log in before posting a comment.", redirect: "/login" },
    "/login"                     => { message: "The username or password is incorrect.",    redirect: "/login" }
  }

  def css(*stylesheets)
    css_link_tags = stylesheets.map do |stylesheet|
      "<link href=\"/#{stylesheet}.css\" media=\"screen, projection\" rel=\"stylesheet\" />"
    end
    css_link_tags.join
  end

  def check_current(path="/")
    (request.path == path || request.path == path + "/") ? "current" : nil
  end

  def set_title
    @title ||= "Snippet"
  end

  def new_user(params)
    new_user = User.new username: params["username"],
                        password: params["password"],
                        email:    params["email"]

    new_user.password_confirmation = params["confirm_password"]
    new_user
  end

  def warden
    env["warden"]
  end

  def current_user
    warden.user
  end

  def renew_session_id
    env["rack.session.options"][:renew] = true
  end

  def format_errors(user_errors, *additional_messages)
    messages   = user_errors.full_messages.map { |message| "<li>#{message}</li>" }
    additional = additional_messages.map       { |message| "<li>#{message}</li>" }

    "<ul>\n" + messages.join("\n") + additional.join("\n") + "</ul>"
  end

  def get_formatter(type)
    Module.const_get(type.capitalize + "Formatter").new
  rescue NameError => e
    raise ArgumentError, "There is no formatter for type '#{type}' OR the formatter is broken"
  end

  def plain_text_url(snippet)
    "/snippet/#{snippet.id}/plain"
  end

  def snippet_types
    {
      "plain" => "Plain text",
      "ruby"  => "Ruby",
      "java"  => "Java"
    }
  end

  def unauthorized_redirect_for(path)
    unauthorized = unauthorized_for(path)
    unauthorized && unauthorized[:redirect]
  end

  def unauthorized_message_for(path)
    unauthorized = unauthorized_for(path)
    unauthorized && unauthorized[:message]
  end

  def unauthorized_for(path)
    # Get string literal match
    unauthorized = UNAUTHORIZED[path]

    # If not string literal match, check if path matches a regex key
    unless unauthorized
      key = UNAUTHORIZED.keys.find { |key| key.is_a?(Regexp) && key =~ path }
      unauthorized = UNAUTHORIZED[key]
    end

    # Return unauthorized or nil
    unauthorized
  end

  def logged_in?
    not current_user.nil?
  end

  # Because a hash cannot be saved in the flash (marshalled)
  # save each entry separately.
  def save_registration_params(params)
    session[:fail_username] = params[:username]
    session[:fail_email]    = params[:email]
    session[:fail_phone]    = params[:phone]
  end

  def delete_registration_params
    session[:fail_username] = nil
    session[:fail_email]    = nil
    session[:fail_phone]    = nil
  end
end

module LoginHelper

  MAX_LOGIN_ATTEMPTS = 5
  LOGIN_LOCKOUT_MINUTES = 20

  def login_attempts
    @login_attempts ||= LoginAttempts.get(env["REMOTE_ADDR"]) ||
                        LoginAttempts.create(ip_address: env["REMOTE_ADDR"])
  end

  def login_locked?
    if lock_set?
      not lock_expired?
    else
      check_login_lockout
      false
    end
  end

  def lock_expired?
    if Time.now.to_i >= login_lock_expire_time
      reset_login_state 
      true
    else
      false
    end
  end

  def check_login_lockout
    increment_login_attempts
    assign_lock if no_more_attempts?
  end

  def lock_set?
    not login_attempts.lock.nil?
  end

  def assign_lock
    login_attempts.update(lock: Time.now.to_i)
  end

  def no_more_attempts?
    login_attempts.attempts >= MAX_LOGIN_ATTEMPTS
  end

  def increment_login_attempts
    login_attempts.update(attempts: login_attempts.attempts + 1)
  end

  def reset_login_state
    login_attempts.destroy
    @login_attempts = nil
  end

  def login_locked_message
    "You have failed to login too many times in a row. " + 
    "You must wait #{login_lock_time_remaining} before attempting to log in again."
  end

  def login_lock_time_remaining
    seconds = login_lock_expire_time - Time.now.to_i
    "#{seconds / 60} minutes, #{seconds % 60} seconds"
  end

  def login_lock_expire_time
    login_attempts.lock + (60 * LOGIN_LOCKOUT_MINUTES)
  end
end
