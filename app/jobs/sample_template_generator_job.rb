# Job responsible for generating Excel spreadsheet templates from samples
class SampleTemplateGeneratorJob < SeekJob
  queue_as QueueNames::SAMPLES

  attr_reader :sample_type_id

  def initialize(sample_type)
    @sample_type_id = sample_type.id
  end

  def perform_job(item)
    item.generate_template
  end

  def gather_items
    [sample_type].compact
  end

  private

  def sample_type
    SampleType.find_by_id(sample_type_id)
  end
end
