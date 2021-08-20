class ProjectCreationMessageLog < MessageLog
  default_scope { where(message_type: :project_creation_request) }

  # project creation requests that haven't been responded to
  scope :pending_requests, -> { pending }

  def self.log_request(sender, programme, project, institution)
    details = {}
    details[:institution] = institution.attributes
    details[:project] = project.attributes
    details[:programme] = programme&.attributes
    # FIXME: needs a subject, but can't use programme as it will save it if it is new
    ProjectCreationMessageLog.create(subject: sender, sender: sender, details: details.to_json)
  end

  # whether the person can respond to the creation request
  # TODO: this will be refactored into a more general method
  def can_respond_project_creation_request?(user_or_person)
    return false unless project_creation_request?
    return false if user_or_person.nil?

    person = user_or_person.person

    log_details = JSON.parse(details)

    return person.is_admin? if log_details['programme'].blank?

    programme = Programme.new(log_details['programme'])

    if programme.id.nil?
      person.is_admin?
    else
      (person.is_admin? && programme.site_managed?) || person.is_programme_administrator?(programme)
    end
  end
end
