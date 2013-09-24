#encoding: utf-8

Warden::Strategies.add(:password) do
  def valid?
    params["username"] && params["password"]
  end

  def authenticate!
    user = User.first(username: params["username"])
    
    if user.nil?
      fail!("The username you entered does not exist.")
    elsif user.authenticate(params["password"])
      success!(user)
    else
      fail!("Could not log in")
    end
  end
end

Warden::Manager.before_failure do |env,opts|
  env['REQUEST_METHOD'] = 'POST'
end

