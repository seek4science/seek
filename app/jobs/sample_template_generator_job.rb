# Job responsible for generating Excel spreadsheet templates from samples
class SampleTemplateGeneratorJob < SeekJob
  queue_as QueueNames::SAMPLES

  def perform(sample_type)
    sample_type.generate_template
  end
end
