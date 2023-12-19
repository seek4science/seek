# Message logs related to Project importation requests
class ProjectImportationMessageLog < MessageLog
    include Seek::ProjectMessageLogDetails
  
    default_scope { where(message_type: :project_importation_request) }
  
    # project importation requests that haven't been responded to
    scope :pending_requests, -> { pending }
  
    def self.log_request(sender:, people:, project:, institution:, programme: nil)
      details = details_json(programme: programme, project: project, institution: institution, people: people)
      # FIXME: needs a subject, but can't use programme as it will save it if it is new
      ProjectImportationMessageLog.create(subject: sender, sender: sender, details: details)
    end
  
    # whether the person can respond to the importation request
    # TODO: this will be refactored into a more general method
    def can_respond_project_importation_request?(user_or_person)
      return false unless project_importation_request?
      return false if user_or_person.nil?
  
      person = user_or_person.person
  
      programme = parsed_details.programme
  
      return person.is_admin? if programme.blank?
  
      if programme.id.nil?
        person.is_admin?
      else
        (person.is_admin? && programme.site_managed?) || person.is_programme_administrator?(programme) || programme.allows_user_projects?
      end
    end
  end
  