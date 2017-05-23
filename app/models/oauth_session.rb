class OauthSession < ActiveRecord::Base

  belongs_to :user
  # attr_accessible :access_token, :expires_in, :refresh_token, :provider, :user_id
  validates_uniqueness_of :user_id, scope: :provider

  EXPIRATION_ERROR_MARGIN = 120

  def expires_in=(sec)
    self.expires_at = Time.now + (sec - EXPIRATION_ERROR_MARGIN).seconds
  end

  def expires_in
    expires_at - Time.now
  end

  def expired?
    Time.now > expires_at
  end

end
