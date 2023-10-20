class IsaStudy
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

    unless @source_sample_type.valid?
      @source_sample_type.errors.full_messages.each { |e| errors.add(:base, "[Source sample type]: #{e}") }
    end

    if @source_sample_type.sample_attributes.select { |a| a.isa_tag.nil? }.any?
      errors.add(:base, '[Source sample type]: All attributes must have an ISA tag')
    end

    if @sample_collection_sample_type.sample_attributes.select { |a| a.isa_tag.nil? && !a.title.include?('Input') }.any?
      errors.add(:base,
                 "[Sample collection sample type]: All attributes should have an ISA Tag except for the <em>'Input'</em> attribute (hidden)".html_safe)
    end

    unless @sample_collection_sample_type.valid?
      @sample_collection_sample_type.errors.full_messages.each do |e|
        errors.add(:base, "[Sample collection sample type]: #{e}")
      end
    end

    unless @source_sample_type.sample_attributes.select { |a| a.isa_tag&.isa_source? }.one?
      errors.add(:base, "[Sample type]: Should have exactly one attribute with the 'source' ISA tag selected")
    end

    %i[isa_sample? isa_protocol?].each do |tag_type|
      sample_type_tag_types = @sample_collection_sample_type.sample_attributes.select { |a| a.isa_tag&.send(tag_type) }
      unless sample_type_tag_types.one?
        tag_title = sample_type_tag_types[0]&.isa_tag&.title
        errors.add(:base, "[Sample type]: Should have exactly one attribute with the '#{tag_title}' ISA tag selected")
      end
    end

    return if @sample_collection_sample_type.sample_attributes.any?(&:seek_sample_multi?)

    errors.add(:base, '[Sample Collection sample type]: SEEK Sample Multi attribute is not provided')
  end
end
