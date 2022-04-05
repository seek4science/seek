class Role < ApplicationRecord
  belongs_to :person, required: true, inverse_of: :roles
  belongs_to :scope, polymorphic: true, optional: true, inverse_of: :roles

  validates :person_id, uniqueness: { scope: [:role_type_id, :scope_id, :scope_type] }
  validates :role_type, presence: true
  validate :authorized_to_grant_role
  validate :role_type_matches_scope, if: -> { role_type.present? }
  validate :scope_allows_person, if: -> { scope.present? }

  delegate :key, to: :role_type

  after_commit :queue_update_auth_table

  def self.with_role_key(key)
    where(role_type_id: RoleType.find_by_key!(key))
  end

  def role_type
    RoleType.find_by_id(role_type_id)
  end

  def role_type=(record_or_key)
    self.role_type_id = (record_or_key.is_a?(RoleType) ? record_or_key : RoleType.find_by_key(record_or_key)).id
  end

  def scope_title
    I18n.t(scope.nil? ? 'roles.scopes.system' : scope_type.underscore)
  end

  private

  def role_type_matches_scope
    if scope_type != role_type.scope
      errors.add(:role_type, "is not a valid #{scope_title} role")
    end
  end

  def authorized_to_grant_role
    return unless authorization_checks_enabled
    if scope
      errors.add(:base, "You are not authorized to grant roles in this #{scope_title}") unless scope.can_manage?
    else
      errors.add(:base, "You are not authorized to grant #{scope_title.downcase} roles") unless User.admin_logged_in?
    end
  end

  def scope_allows_person
    if scope.is_a?(Project) && !scope.people.include?(person)
      errors.add(:person, "does not belong to this #{scope_title}")
    end
  end

  def queue_update_auth_table
    AuthLookupUpdateQueue.enqueue(person) if person
  end
end
