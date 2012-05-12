class SpecialAuthCode < ActiveRecord::Base
  belongs_to :asset, :polymorphic => true
  default_scope :conditions => ['expiration_date > ?', Date.today]

  after_initialize :defaults

  named_scope :unexpired, :conditions => ['expiration_date > ?', Time.now]

  def can_edit?(u=User.current_user)
    asset.can_manage?(u)
  end
  alias_method :can_manage?, :can_edit?

  def defaults
    self.code = SecureRandom.base64(30) if code.blank?
    self.expiration_date = Time.now + 14.days if expiration_date.blank?
  end

  validates_presence_of :code, :expiration_date

  @@current_auth_code = nil
  def self.with_auth_code auth_code
    original_value = @@current_auth_code
    @@current_auth_code = unexpired.find_by_code(auth_code)
    yield
  ensure
    @@current_auth_code = original_value
  end

  def self.current_auth_code
    @@current_auth_code
  end
end
