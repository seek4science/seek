class ApiToken < ApplicationRecord
  API_TOKEN_LENGTH = 40

  validates :title, presence: true

  before_create :generate_token

  belongs_to :user

  attr_reader :token

  def self.random_api_token
    SecureRandom.urlsafe_base64(API_TOKEN_LENGTH).first(API_TOKEN_LENGTH)
  end

  def self.encrypt_token(token)
    Digest::SHA256.hexdigest("--#{token}--")
  end

  # Could this credential be one of these at all? Tokens are urlsafe base64 and so hold no dots,
  # which is what tells an OpenID Connect access token apart from one of these without looking
  # either up. The test is on the alphabet rather than the length, so that a token issued when
  # API_TOKEN_LENGTH was something else is still recognised.
  def self.plausible_token?(credential)
    credential.to_s.match?(/\A[A-Za-z0-9_-]{2,}\z/)
  end

  private

  def generate_token
    @token = self.class.random_api_token
    self.encrypted_token = self.class.encrypt_token(@token)
  end
end
