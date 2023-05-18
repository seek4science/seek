require 'digest/sha1'

class User < ApplicationRecord
  MIN_PASSWORD_LENGTH = 10
  MAX_LOGIN_LENGTH = 120
  MIN_LOGIN_LENGTH = 3

  acts_as_annotation_source

  acts_as_tagger

  belongs_to :person

  has_many :identities, dependent: :destroy
  has_many :oauth_sessions, dependent: :destroy
  has_many :api_tokens, dependent: :destroy
  # Doorkeeper-related
  has_many :access_grants,
           class_name: "Doorkeeper::AccessGrant",
           foreign_key: :resource_owner_id,
           dependent: :destroy
  has_many :access_tokens,
           class_name: "Doorkeeper::AccessToken",
           foreign_key: :resource_owner_id,
           dependent: :destroy
  has_many :oauth_applications,
           class_name: "Doorkeeper::Application",
           as: :owner

  # restful_authentication plugin generated code ...
  # Virtual attribute for the unencrypted password
  attr_accessor :password, :password_confirmation

  validates     :login, presence: true
  validates     :password, presence: true, if: :password_required?
  validates     :password_confirmation, presence: true, if: :password_required?
  validates_length_of       :password, minimum: MIN_PASSWORD_LENGTH, if: :password_required?
  validates_confirmation_of :password, if: :password_required?
  validates_length_of       :login, within: MIN_LOGIN_LENGTH..MAX_LOGIN_LENGTH
  validates_uniqueness_of   :login, case_sensitive: false

  validates :email, format: { with: RFC822::EMAIL }, if: -> { email }
  validates :email, presence: true, if: :check_email_present?
  validate :email_available?, if: :check_email_present?

  before_save :encrypt_password
  before_create :make_activation_code

  # virtual attribute to hold email used to determine whether this user links to an existing
  attr_accessor :email
  attr_writer :check_email_present

  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  # attr_accessible :login, :password, :password_confirmation, :email

  has_many :favourite_groups, dependent: :destroy

  scope :not_activated, -> { where.not(activation_code:nil).where.not(person:nil) }

  acts_as_uniquely_identifiable

  cattr_accessor :current_user

  delegate :is_admin?, to: :person, allow_nil: true
  delegate :is_project_administrator?, to: :person, allow_nil: true
  delegate :is_admin_or_project_administrator?, to: :person, allow_nil: true
  delegate :is_programme_administrator?, to: :person, allow_nil: true

  after_commit :queue_update_auth_table, on: :create

  after_destroy :remove_from_auth_tables

  # related_#{type} are resources that user created
  RELATED_RESOURCE_TYPES = %i[data_files models sops events presentations publications].freeze
  RELATED_RESOURCE_TYPES.each do |type|
    define_method "related_#{type}" do
      person.send "related_#{type}"
    end
  end

  def check_email_present?
    !!@check_email_present
  end

  def self.admin_logged_in?
    logged_in_and_registered? && current_user.person.is_admin?
  end

  def self.project_administrator_logged_in?
    logged_in_and_registered? && current_user.person.is_project_administrator_of_any_project?
  end

  def self.programme_administrator_logged_in?
    logged_in_and_registered? && current_user.person.is_programme_administrator_of_any_programme?
  end

  # programme administrator logged in, but only of activated programmes
  def self.activated_programme_administrator_logged_in?
    programme_administrator_logged_in? && current_user.person.administered_programmes.activated.any?
  end

  def self.admin_or_project_administrator_logged_in?
    project_administrator_logged_in? || admin_logged_in?
  end

  def self.asset_housekeeper_logged_in?
    logged_in_and_registered? && current_user.person.is_asset_housekeeper?
  end

  # a person can be logged in but not fully registered during
  # the registration process whilst selecting or creating a profile
  def self.logged_in_and_registered?
    logged_in? && current_user.person && current_user.person.id
  end

  def self.logged_in_and_member?
    logged_in? && current_user.person.try(:member?)
  end

  def self.logged_in?
    current_user
  end

  # Activates the user in the database.
  def activate    
    @activated = true
    self.activated_at = Time.now.utc
    self.activation_code = nil
    save(validate: false)

    #clear message logs if associated with a person (might not be when automatically activated when activation is required)
    ActivationEmailMessageLog.activation_email_logs(person).destroy_all unless person.nil?
  end

  def assets
    sops | models | data_files
  end

  def active?
    # the existence of an activation code means they have not activated yet
    activation_code.nil?
  end

  # Authenticates a user by their email address or login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(email_or_login, password)
    user = get_user(email_or_login)  # need to get the salt
    user && user.authenticated?(password) ? user : nil
  end

  def self.get_user(email_or_login)
    User.joins(:person).where(people: { email: email_or_login }).first ||
      User.where(login: email_or_login).first
  end

  # Encrypts some data with the salt.
  def self.sha1_encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  def self.sha256_encrypt(password, salt)
    Digest::SHA256.hexdigest("--#{salt}--#{password}--")
  end

  def self.encrypt(password, salt)
    sha256_encrypt(password, salt)
  end

  # Encrypts the password with the user salt
  def sha1_encrypt(password)
    self.class.sha1_encrypt(password, salt)
  end

  def sha256_encrypt(password)
    self.class.sha256_encrypt(password, salt)
  end

  alias_method :encrypt, :sha256_encrypt

  def authenticated?(password)
    if crypted_password == encrypt(password)
      true
    elsif crypted_password == sha1_encrypt(password)
      update_column(:crypted_password, encrypt(password))
      true
    else
      false
    end
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    remember_me_for 6.months
  end

  def remember_me_for(time)
    remember_me_until time.from_now.utc
  end

  def remember_me_until(time)
    self.remember_token_expires_at = time
    self.remember_token            = encrypt("#{login}--#{remember_token_expires_at}")
    save(validate: false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(validate: false)
  end

  # Returns true if the user has just been activated.
  def recently_activated?
    @activated
  end

  # performs a simple conversion from an array of user's project instances into a hash { <project_id> => <project_name>, [...] }
  def generate_own_project_id_name_hash
    Hash[*person.projects.collect { |p|; [p.id, p.name]; }.flatten]
  end

  # returns a 'allowlist' favourite group for the user (or 'nil' if not found)
  def get_allowlist
    FavouriteGroup.where(user_id: id, name: FavouriteGroup::ALLOWLIST_NAME).first
  end

  # returns a 'denylist' favourite group for the user (or 'nil' if not found)
  def get_denylist
    FavouriteGroup.where(user_id: id, name: FavouriteGroup::DENYLIST_NAME).first
  end

  def currently_online
    false
  end

  def display_name
    person.name
  end

  def can_manage_types?
    return false unless Seek::Config.type_managers_enabled

    case Seek::Config.type_managers
    when 'admins'
      if User.admin_logged_in?
        return true
      else
        return false
      end
    when 'pals'
      if User.admin_logged_in? || User.pal_logged_in?
        return false
      else
        return false
      end
    when 'users'
      return false
    when 'none'
      return false
    end
  end

  def self.with_current_user(user)
    previous = current_user
    self.current_user = user
    begin
      yield
    ensure
      User.current_user = previous
    end
  end

  def reset_password
    self.reset_password_code_until = 1.day.from_now
    self.reset_password_code = Digest::SHA1.hexdigest("#{login}#{Time.now.to_s.split(//).sort_by { rand }.join}")
  end

  # indicates whether the user has completed the registration process, and is associated with a profile and link has been saved
  def registration_complete?
    person.try(:persisted?) && person.user.try(:persisted?)
  end

  def self.without_profile
    User.includes(:person).select { |u| u.person.nil? }
  end

  # set the code and the until time to nil. object needs to be saved to take effect
  def clear_reset_password_code
    self.reset_password_code = nil
    self.reset_password_code_until = nil
  end

  def self.from_omniauth(auth)
    User.new.tap do |user|
      user.login = unique_login(auth['info']['nickname'] || 'user')
      user.password = random_password
      user.password_confirmation = user.password
    end
  end

  def self.from_api_token(token)
    joins(:api_tokens).where(api_tokens: { encrypted_token: ApiToken.encrypt_token(token) }).first
  end

  def uses_omniauth?
    identities.any?
  end

  protected

  # before filter
  def encrypt_password
    return if password.blank?
    self.salt = Digest::SHA1.hexdigest("--#{Time.now}--#{login}--") if new_record?
    self.crypted_password = encrypt(password)
  end

  def password_required?
    crypted_password.blank? || !password.blank?
  end

  def make_activation_code
    self.activation_code = Digest::SHA1.hexdigest(Time.now.to_s.split(//).sort_by { rand }.join)
  end

  def email_available?
    found = Person.where(email: email).select(&:user).any?
    if found
      errors.add(:email, 'The email has already been registered')
      return false
    end
  end

  def queue_update_auth_table
    AuthLookupUpdateQueue.enqueue(self)
  end

  def remove_from_auth_tables
    Seek::Util.authorized_types.each do |type|
      type.lookup_class.where(user: id).in_batches(of:1000).delete_all
    end
  end

  def self.unique_login(original_login)
    login = original_login
    while User.where(login: login).exists? do
      login = "#{original_login}#{rand(9999).to_s.rjust(4, '0')}"
    end

    login
  end

  def self.random_password
    SecureRandom.urlsafe_base64(MIN_PASSWORD_LENGTH).first(MIN_PASSWORD_LENGTH)
  end
end
