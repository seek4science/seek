# Job responsible for generating Excel spreadsheet templates from samples
class SampleTemplateGeneratorJob < TaskJob
  queue_as QueueNames::SAMPLES

  def perform(sample_type)
    sample_type.generate_template
  end

  def task
    arguments[0].template_generation_task
  end
end
