class SampleTemplateGeneratorJob < SeekJob

  attr_reader :sample_type

  def initialize(sample_type)
    @sample_type = sample_type
  end

  def perform_job(sample_type)
    sample_type.generate_template
  end

  def gather_items
    [sample_type]
  end

  def allow_duplicate_jobs?
    false
  end

end