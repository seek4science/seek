class ISAStudy
  include ActiveModel::Model

  attr_accessor :study, :source_sample_type, :sample_collection_sample_type

  delegate :source_sample_type, to: :sample_type, prefix: true
  delegate :sample_collection_sample_type, to: :sample_type, prefix: true

  validates_presence_of :study, :source_sample_type, :sample_collection_sample_type
  validate :validate_objects

  def initialize(params = {})
    @study = Study.new((params[:study] || {}))

    @source_sample_type = SampleType.new((params[:source_sample_type] || {}).merge({ project_ids: @study.project_ids }))
    @sample_collection_sample_type = SampleType.new((params[:sample_collection_sample_type] || {}).merge({ project_ids: @study.project_ids }))

    @source_sample_type.sample_attributes.build(is_title: true, required: true) unless params[:source_sample_type]
    return if params[:sample_collection_sample_type]

    @sample_collection_sample_type.sample_attributes.build(is_title: true, required: true)
  end

  def save
    if valid?
      if @study.new_record?
        input_attribute = @sample_collection_sample_type.sample_attributes.detect(&:seek_sample_multi?)
        input_attribute.linked_sample_type = @source_sample_type
        title = @source_sample_type.sample_attributes.detect(&:is_title).title
        input_attribute.title = "Input (#{title})"
        @study.sample_types = [@source_sample_type, @sample_collection_sample_type]
      end
      @study.save
      @source_sample_type.save
      @sample_collection_sample_type.save
    else
      false
    end
  end

  attr_reader :study

  def source
    @source_sample_type
  end

  def sample_collection
    @sample_collection_sample_type
  end

  def can_manage?(user = User.current_user)
    user && user.person == @study.contributor
  end

  def isa_object
    @study
  end

  def populate(id)
    @study = Study.find(id)
    @source_sample_type = @study.sample_types.first
    @sample_collection_sample_type = @study.sample_types.second
  end

  private

  def validate_objects
    @study.errors.each { |e| errors.add(:base, "[Study]: #{e.full_message}") } unless @study.valid?

    [@source_sample_type, @sample_collection_sample_type].each do |sample_type|
      # Add generic Sample type errors
      unless sample_type.valid?
        sample_type.errors.full_messages.each do |e|
          errors.add(:base, "[Sample type '#{sample_type.title}']: #{e}")
        end
      end

      # All Sample Attributes must have an ISA tag
      missing_tag_attributes = sample_type.sample_attributes.select { |a| a.isa_tag.nil? }
      missing_tag_attributes.each do |attribute|
        errors.add(:base, "[Sample type '#{sample_type.title}']: #{attribute.title} does not have an ISA tag.")
      end
    end

    # Source sample type must have exactly one SOURCE attribute
    unless @source_sample_type.sample_attributes.select { |a| a.isa_tag&.isa_source? }.one?
      errors.add(:base, "[Sample type '#{@source_sample_type.title}']: Should have exactly one attribute with the '#{Seek::ISA::TagType::INPUT}' ISA tag selected")
    end

    # Sample collection sample type must have at exactly one attribute with these ISA tags:
    # - SAMPLE
    # - PROTOCOL
    # - INPUT
    [Seek::ISA::TagType::SAMPLE, Seek::ISA::TagType::PROTOCOL, Seek::ISA::TagType::INPUT].each do |tag_type|
      sample_type_tag_types = @sample_collection_sample_type.sample_attributes.select { |a| a.isa_tag&.title == tag_type }
      unless sample_type_tag_types.one?
        errors.add(:base, "[Sample type '#{@sample_collection_sample_type.title}']: Should have exactly one attribute with the '#{tag_type}' ISA tag selected")
      end
    end

    # The input attribute must conform to these restrictions:
    # - Input ISA tag
    # - 'input' in the title
    # - Sample attribute type must be 'Registered Sample List'
    if @sample_collection_sample_type.sample_attributes.detect { |attribute| attribute.input_attribute? }.nil?
      attribute_type_title = SampleAttributeType.find_by(base_type: Seek::Samples::BaseType::SEEK_SAMPLE_MULTI)&.title
      errors.add(:base, "[Sample type '#{@sample_collection_sample_type.title}']: No valid input attribute detected! A valid input attribute must have an '#{Seek::ISA::TagType::INPUT}' ISA tag, have 'input in the title' and must be of type '#{attribute_type_title}'.")
    end
  end
end
