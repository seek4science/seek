class IsaAssay
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
        input_attribute = @sample_type.sample_attributes.detect(&:seek_sample_multi?)
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

    @sample_type.errors.full_messages.each { |e| errors.add(:base, "[Sample type]: #{e}") } unless @sample_type.valid?

    unless @sample_type.sample_attributes.any?(&:seek_sample_multi?)
      errors.add(:base, '[Sample type]: SEEK Sample Multi attribute is not provided')
    end

    unless @sample_type.sample_attributes.select { |a| a.isa_tag&.isa_protocol? }.one?
      errors.add(:base, "[Sample type]: Should have exactly one attribute with the 'protocol' ISA tag selected")
    end

    unless @sample_type.sample_attributes.select { |a| a.title.include?('Input') && a.isa_tag.nil? }.one?
      errors.add(:base,
                  "[Sample type]: Should have exactly one attribute with the title 'Input' <u><b>and</b></u> no ISA tag".html_safe)
    end

    if @sample_type.sample_attributes.select { |a| !a.title.include?('Input') && a.isa_tag.nil? }.any?
      errors.add(:base,
                  "[Sample type]: All attributes should have an ISA Tag except for the <em>'Input'</em> attribute (hidden)".html_safe)
    end

    assay_sample_or_datafile_attributes = @sample_type.sample_attributes.select do |a|
      a.isa_tag&.isa_other_material? || a.isa_tag&.isa_data_file?
    end

    unless assay_sample_or_datafile_attributes.one?
      errors.add(:base,
                  "[Sample type]: Should have exactly one attribute with the 'data_file' <u><b>or</b></u> 'other_material' ISA tag selected".html_safe)
    end
    errors.add(:base, '[Input Assay]: Input Assay is not provided') if @input_sample_type_id.blank?
  end
end
