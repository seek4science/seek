class Identity < ActiveRecord::Base
  belongs_to :user

  def self.from_omniauth(auth)
    Identity.where(provider: auth.provider, uid: auth.uid).first_or_initialize
  end
end
