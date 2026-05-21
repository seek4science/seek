class ISAAssay
  include ActiveModel::Model

  attr_accessor :assay, :sample_type, :input_sample_type_id

  validates_presence_of :assay
  validate :validate_objects

  def initialize(params = {})
    @assay = Assay.new(params[:assay] || {})
    unless @assay.is_assay_stream?
      @sample_type = SampleType.new((params[:sample_type] || {}).merge({ project_ids: @assay.project_ids }))
      @sample_type.sample_attributes.build(is_title: true, required: true) unless params[:sample_type]
      @assay.sample_type = @sample_type
    end

    @input_sample_type_id = params[:input_sample_type_id]
  end

  def save
    if valid?
      if @assay.new_record? && !@assay.is_assay_stream?
        # connect the sample type multi link attribute to the last sample type of the assay's study
        input_attribute = @sample_type.sample_attributes.detect(&:input_attribute?)
        input_attribute.linked_sample_type_id = @input_sample_type_id
        title = SampleType.find(@input_sample_type_id).sample_attributes.detect(&:is_title).title
        input_attribute.title = "Input (#{title})"
      end
      @sample_type.save unless @assay.is_assay_stream?
      @assay.save
    else
      false
    end
  end

  attr_reader :assay, :sample_type

  def can_manage?(user = User.current_user)
    user && user.person == @assay.contributor
  end

  def isa_object
    @assay
  end

  def populate(id)
    @assay = Assay.find(id)
    @sample_type = @assay.sample_type
    if @sample_type
      @input_sample_type_id = @sample_type.sample_attributes.detect(&:seek_sample_multi?).linked_sample_type_id
    end
  end

  private

  def validate_objects
    @assay.errors.each { |e| errors.add(:base, "[Assay]: #{e.full_message}") } unless @assay.valid?

    if @assay.new_record? && @assay.next_linked_child_assay&.sample_type&.samples&.any?
      next_assay_id = @assay.next_linked_child_assay.id
      next_assay_title = @assay.next_linked_child_assay.title
      errors.add(:base, "[Assay]: Not allowed to create an assay before assay '#{next_assay_id} - #{next_assay_title}'. It has samples linked to it.")
    end

    return if @assay.is_assay_stream?

    errors.add(:base, '[Assay]: The assay is missing a sample type.') if @sample_type.nil?

    return unless @sample_type

    # In case of an experimental Assay, it must  have an input sample type
    errors.add(:base, '[Input Assay]: Input Assay is not provided') if @input_sample_type_id.blank?

    # Add generic Sample type errors
    @sample_type.errors.full_messages.each { |e| errors.add(:base, "[Sample type]: #{e}") } unless @sample_type.valid?

    # All Sample Attributes must have an ISA tag
    missing_tag_attributes = @sample_type.sample_attributes.select { |a| a.isa_tag.nil? }
    missing_tag_attributes.each do |attribute|
      errors.add(:base,
                 "[Sample type]: Attribute '#{attribute.title}' is missing an ISA Tag.")
    end

    # The Sample type must have at exactly one attribute with these ISA tags:
    # - PROTOCOL
    # - INPUT
    [Seek::ISA::TagType::PROTOCOL, Seek::ISA::TagType::INPUT].each do |tag_type|
      sample_type_tag_types = @sample_type.sample_attributes.select { |a| a.isa_tag&.title == tag_type }
      unless sample_type_tag_types.one?
        errors.add(:base, "[Sample type]: Should have exactly one attribute with the '#{tag_type}' ISA tag selected")
      end
    end

    # The Sample type must have at least one attribute with one of the ISA tags:
    # - OTHER_MATERIAL
    # - DATA_FILE
    assay_sample_or_datafile_attributes = @sample_type.sample_attributes.select do |a|
      a.isa_tag&.isa_other_material? || a.isa_tag&.isa_data_file?
    end

    unless assay_sample_or_datafile_attributes.one?
      errors.add(:base,
                  "[Sample type]: Should have exactly one attribute with the 'data_file' or 'other_material' ISA tag selected")
    end

    # The input attribute must conform to these restrictions:
    # - Input ISA tag
    # - 'input' in the title
    # - Sample attribute type must be 'Registered Sample List'
    if @sample_type.sample_attributes.detect { |attribute| attribute.input_attribute? }.nil?
      attribute_type_title = SampleAttributeType.find_by(base_type: Seek::Samples::BaseType::SEEK_SAMPLE_MULTI)&.title
      errors.add(:base, "[Sample type '#{@sample_type.title}']: No valid input attribute detected! A valid input attribute must have an '#{Seek::ISA::TagType::INPUT}' ISA tag, have 'input in the title' and must be of type '#{attribute_type_title}'.")
    end
  end
end
