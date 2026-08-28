class ISAAssay
  include ActiveModel::Model

  attr_accessor :assay, :sample_type, :input_sample_type_id

  validates_presence_of :assay
  validates_presence_of :sample_type, unless: -> { assay_stream? }
  validate :validate_assay, if: -> { @assay.present? }
  validate :validate_sample_type, if: -> { errors.blank? && !@assay.is_assay_stream? }

  private def assay_stream? = @assay&.is_assay_stream?

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
    @assay = Assay.find_by(id:)
    @sample_type = @assay&.sample_type
    if @sample_type
      @input_sample_type_id = @sample_type.sample_attributes.detect(&:seek_sample_multi?).linked_sample_type_id
    end
  end

  private

  def validate_assay
    @assay.errors.each { |e| errors.add(:assay, "#{e.full_message}") } unless @assay.valid?

    if @assay.new_record? && @assay.next_linked_child_assay&.sample_type&.samples&.any?
      next_assay_id = @assay.next_linked_child_assay.id
      next_assay_title = @assay.next_linked_child_assay.title
      errors.add(:assay, "Not allowed to create an assay before assay '#{next_assay_id} - #{next_assay_title}'. It has samples linked to it.")
    end

  end

  def validate_sample_type
    # A missing sample type is already reported by the presence validator
    return if @sample_type.nil?

    # In case of an experimental Assay, it must  have an input sample type
    errors.add(:base, '[Input Assay]: Input Assay is not provided') if @input_sample_type_id.blank?

    # Add Sample type generic validation errors
    @sample_type.errors.full_messages.each { |e| errors.add(:sample_type, "#{e}") } unless @sample_type.valid?

    # All Sample Attributes must have an ISA tag
    if @sample_type.sample_attributes.select { |a| a.isa_tag.nil? }.any?
      errors.add(:sample_type,
                 "All attributes should have an ISA Tag.")
    end

    # The Sample type must have exactly one attribute with a 'protocol' ISA tag
    unless @sample_type.sample_attributes.select { |a| a.isa_tag&.isa_protocol? }.one?
      errors.add(:sample_type, "Should have exactly one attribute with the 'protocol' ISA Tag.")
    end

    # The Sample type must have exactly one attribute with one of the ISA tags:
    # - other_material
    # - data_file
    assay_sample_or_datafile_attributes = @sample_type.sample_attributes.select do |a|
      a.isa_tag&.isa_other_material? || a.isa_tag&.isa_data_file?
    end

    unless assay_sample_or_datafile_attributes.one?
      errors.add(:sample_type,
                 "Should have exactly one attribute with the 'data_file' or 'other_material' ISA tag selected")
    end

    # The input attribute must conform to these restrictions:
    # - 'input' ISA tag
    # - 'input' in the title
    # - Sample attribute type must be 'Registered Sample List'
    if @sample_type.sample_attributes.detect { |attribute| attribute.input_attribute? }.nil?
      attribute_type_title = SampleAttributeType.find_by(base_type: Seek::Samples::BaseType::SEEK_SAMPLE_MULTI)&.title
      errors.add(:sample_type, "No valid input attribute detected! A valid input attribute must have an '#{Seek::ISA::TagType::INPUT}' ISA tag, have 'input' in the title and must be of type '#{attribute_type_title}'.")
    end
  end
end
