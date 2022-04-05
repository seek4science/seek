class GroupMembership < ApplicationRecord
  belongs_to :person, inverse_of: :group_memberships
  belongs_to :work_group, inverse_of: :group_memberships, validate: true
  has_one :project, through: :work_group, inverse_of: :group_memberships
  has_one :institution, through: :work_group, inverse_of: :group_memberships

  before_save :unset_has_left
  after_save :remember_previous_person
  after_update { remove_former_project_roles if has_left }
  after_commit :queue_update_auth_table

  after_destroy do
    remove_former_project_roles
    destroy_empty_work_group
  end

  validates :work_group,:presence => {:message=>"A workgroup is required"}

  def has_left=(yes = false)
    if yes
      self.time_left_at ||= Time.now
    else
      self.time_left_at = nil
    end
    super(yes)
  end

  # For now the `has_left` boolean field is just to indicate that the job has run, but in future consider also using it
  # for a more efficient query to get old/current project members.
  def has_left
    super || time_left_at&.past?
  end

  def remember_previous_person
    @previous_person_id = person_id_before_last_save
  end

  def queue_update_auth_table
    people = [Person.find_by_id(person_id)]
    people << Person.find_by_id(@previous_person_id) unless @previous_person_id.blank?

    AuthLookupUpdateQueue.enqueue(people.compact.uniq)
  end

  #whether the person can remove this person from the project. If they are an administrator and related programme administrator they can, but otherwise they cannot remove themself.
  #this is to prevent a project admin accidently removing themself and leaving the project un-administered
  def person_can_be_removed?
    !person.me? || User.current_user.is_admin? || person.is_programme_administrator?(project.programme)
  end

  def self.due_to_expire
    where('time_left_at IS NOT NULL AND time_left_at <= ?', Time.now).where(has_left: false)
  end

  private

  def remove_former_project_roles
    wg = WorkGroup.find_by_id(work_group_id)
    return unless wg
    project = Project.find_by_id(wg.project_id)
    person.remove_dangling_project_roles if project && person.persisted?
  end

  def destroy_empty_work_group
    wg = WorkGroup.find_by_id(work_group_id)

    wg.destroy if wg && wg.people.empty?
  end

  def unset_has_left
    self.has_left = false if time_left_at.nil?
  end
end
