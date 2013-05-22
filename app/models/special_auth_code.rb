class SpecialAuthCode < ActiveRecord::Base
  belongs_to :asset, :polymorphic => true
  default_scope :conditions => ['expiration_date > ?', Date.today]

  after_initialize :defaults

  scope :unexpired, :conditions => ['expiration_date > ?', Time.now]

  def can_manage?(u=User.current_user)
    asset.can_manage?(u)
  end

  def can_edit?(u=User.current_user)
    can_manage?(u)
  end

  def defaults
    self.code = SecureRandom.base64(30) if code.blank?
    self.expiration_date = Time.now + 14.days if expiration_date.blank?
  end

  validates_presence_of :code, :expiration_date
end
