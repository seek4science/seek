class Identity < ActiveRecord::Base
  belongs_to :user

  def self.from_omniauth(auth)
    # TODO: Decide what to do about users who have an account but authenticate later on via Elixir AAI.
    # TODO: The code below will update their account to note the Elixir auth. but leave their password intact;
    # TODO: is this what we should be doing?

    auth_info = { provider: auth.provider,
                  uid: auth.uid }
    auth_info[:email] = auth.info.email if auth.info.email

    Identity.where(provider: auth.provider, uid: auth.uid).first_or_initialize(auth_info)
  end
end
