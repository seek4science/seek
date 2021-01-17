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

  private

  def generate_token
    @token = self.class.random_api_token
    self.encrypted_token = self.class.encrypt_token(@token)
  end
end
