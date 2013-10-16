#encoding: utf-8

Warden::Strategies.add(:password) do
  def valid?
    params["username"] && params["password"]
  end

  def authenticate!
    success! env["warden"].user if env["warden"].user
    user = User.first(username: params["username"])

    if user.nil? || !user.authenticate(params["password"])
      fail!
    else
      success! user
    end
  end
end

# To ensure that fail route (POST) in the app
Warden::Manager.before_failure do |env, opts|
  env["REQUEST_METHOD"] = "POST"
end
