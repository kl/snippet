#encoding: utf-8

module AppHelper

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
end
