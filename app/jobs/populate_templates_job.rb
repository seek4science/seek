# extracts Templates and Templates attributes from given json files and stores them in the DB
class PopulateTemplatesJob < ApplicationJob
  queue_with_priority 1
  queue_as QueueNames::TEMPLATES
  def perform
    return unless Seek::Config.isa_json_compliance_enabled

    Seek::IsaTemplates::TemplateExtractor.extract_templates
  end
end
