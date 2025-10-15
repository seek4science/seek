# extracts Templates and Templates attributes from given json files and stores them in the DB
class PopulateTemplatesJob < ApplicationJob
  queue_with_priority 1
  queue_as QueueNames::TEMPLATES
  def perform(user)
    return unless Seek::Config.isa_json_compliance_enabled

    Seek::ISATemplates::TemplateExtractor.extract_templates(user)
  end
end
