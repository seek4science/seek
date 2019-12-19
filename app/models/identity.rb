class Identity < ActiveRecord::Base
  belongs_to :user

  def self.from_omniauth(auth)
    # TODO: Decide what to do about users who have an account but authenticate later on via Elixir AAI.
    # TODO: The code below will update their account to note the Elixir auth. but leave their password intact;
    # TODO: is this what we should be doing?
    Identity.where(provider: auth.provider, uid: auth.uid).first_or_initialize(provider: auth.provider,
                                                                               uid: auth.uid)
  end
end
