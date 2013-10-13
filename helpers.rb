#encoding: utf-8

module AppHelper

  UNAUTHORIZED = {
    "/snippet/new" => { message: "You must log in before posting a snippet.",
                        redirect: "/login" },

    %r{/snippet/\d+/comment/new} => { message: "You must log in before posting a comment.",
                                      redirect: "/login" }
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

  def current_user
    env["warden"].user
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
