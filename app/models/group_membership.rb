class GroupMembership < ApplicationRecord
  belongs_to :person, inverse_of: :group_memberships
  belongs_to :work_group, inverse_of: :group_memberships, validate: true
  has_one :project, through: :work_group, inverse_of: :group_memberships
  has_one :institution, through: :work_group, inverse_of: :group_memberships

  before_save :unset_has_left
  after_save :remember_previous_person
  after_save :remember_rdf_change
  after_update { remove_former_project_roles if has_left }
  after_commit :queue_update_auth_table
  # the person's and project's RDF include the membership (jerm:isAssociatedWith)
  after_commit :queue_rdf_generation
  # destroying the last membership also destroys its work group, so the project is found before then
  before_destroy :remember_project

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
    @previous_work_group_id = work_group_id_before_last_save
  end

  # a membership can be saved more than once before the commit, and only the last save's changes are known then
  def remember_rdf_change
    @rdf_changed ||= saved_change_to_person_id? || saved_change_to_work_group_id?
  end

  def remember_project
    @project_id = work_group&.project_id
  end

  def queue_update_auth_table
    people = [Person.find_by_id(person_id)]
    people << Person.find_by_id(@previous_person_id) unless @previous_person_id.blank?

    AuthLookupUpdateQueue.enqueue(people.compact.uniq)
  end

  def queue_rdf_generation
    return unless destroyed? || @rdf_changed

    @rdf_changed = false

    people = [Person.find_by_id(person_id)]
    people << Person.find_by_id(@previous_person_id) unless @previous_person_id.blank?
    projects = [Project.find_by_id(@project_id || work_group&.project_id)]
    projects << WorkGroup.find_by_id(@previous_work_group_id)&.project unless @previous_work_group_id.blank?

    RdfGenerationQueue.enqueue((people + projects).compact.uniq, refresh_dependents: false)
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
