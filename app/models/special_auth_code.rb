class SpecialAuthCode < ApplicationRecord
  belongs_to :asset, polymorphic: true
  default_scope -> { where('expiration_date > ?', Date.today) }

  after_initialize :defaults

  scope :unexpired, -> { where('expiration_date > ?', Time.now) }

  def defaults
    self.code = SecureRandom.base64(30) if code.blank?
    self.expiration_date = Time.now + 14.days if expiration_date.blank?
  end

  validates_presence_of :code, :expiration_date

  validate ->(code) { errors.add(:special_auth_code, 'asset must be manageable') unless code.asset && code.asset.can_manage? }
end
