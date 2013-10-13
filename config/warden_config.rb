#encoding: utf-8

Warden::Strategies.add(:password) do
  def valid?
    params["username"] && params["password"]
  end

  def authenticate!
    user = User.first(username: params["username"])

    if user.nil? || !user.authenticate(params["password"])
      fail! "The username or password is incorrect."
    else
      success! user
    end
  end
end

# To ensure that fail route (POST) in the app
Warden::Manager.before_failure do |env, opts|
  env["REQUEST_METHOD"] = "POST"
end

