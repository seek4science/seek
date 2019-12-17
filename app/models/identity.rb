class Identity < ActiveRecord::Base
  belongs_to :user

  cattr_accessor :current_identity

  def self.from_omniauth(auth)
    # TODO: Decide what to do about users who have an account but authenticate later on via Elixir AAI.
    # TODO: The code below will update their account to note the Elixir auth. but leave their password intact;
    # TODO: is this what we should be doing?
    Identity.current_identity = Identity.where(provider: auth.provider, uid: auth.uid).first_or_create(provider: auth.provider,
                                                                                                       uid: auth.uid,
                                                                                                       email: auth.info.email)
  end
end
