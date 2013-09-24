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

end

# Monkey patches

class DataMapper::Validations::ValidationErrors

  def as_list
    messages = full_messages.map { |message| "<li>#{message}</li>" }
    "<ul>\n" + messages.join("\n") + "</ul>"
  end
end

