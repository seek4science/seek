class IsaStudy
  include ActiveModel::Model
  
  attr_accessor :study, :source_sample_type, :sample_collection_sample_type

  delegate :source_sample_type, to: :sample_type, prefix: true
  delegate :sample_collection_sample_type, to: :sample_type, prefix: true

  validates_presence_of :study, :source_sample_type, :sample_collection_sample_type
  validate :validate_objects

  def initialize (params = {})
    @study = Study.new((params[:study]||{}))

    @source_sample_type = SampleType.new((params[:source_sample_type]||{}).merge({project_ids: @study.project_ids}))
    @sample_collection_sample_type = SampleType.new((params[:sample_collection_sample_type]||{}).merge({project_ids: @study.project_ids}))

    @source_sample_type.sample_attributes.build(is_title: true, required: true) if !params[:source_sample_type] # Initial attribute
    @sample_collection_sample_type.sample_attributes.build(is_title: true, required: true) if !params[:sample_collection_sample_type] # Initial attribute
  end


  def save
    @sample_collection_sample_type.sample_attributes.detect {|a| a.seek_sample_multi?}.linked_sample_type = @source_sample_type
    if valid?
      @study.save
      @source_sample_type.save
      @sample_collection_sample_type.save
      
      @study.sample_types = [@source_sample_type, @sample_collection_sample_type]
      @study.save
    else
      false
    end
  end

  def study
    @study
  end

  def source
    @source_sample_type
  end

  def sample_collection
    @sample_collection_sample_type
  end

  def can_manage?
    false
  end

  private

  def validate_objects
    @study.errors.each {|e| errors[:base] << "[Study]: #{e}" } if !@study.valid?
    errors[:base] << "SOP is required" if !@study.sop_id

    @source_sample_type.errors.each {|e| errors[:base] << "[Source sample type]: #{e}"} if !@source_sample_type.valid?

    @sample_collection_sample_type.errors.each {|e| errors[:base] << 
      "[Sample collection sample type]: #{e}"} if !@sample_collection_sample_type.valid?
    if !@sample_collection_sample_type.sample_attributes.any? {|a| a.seek_sample_multi?}
      errors[:base] << "[Sample Collection sample type]: SEEK Sample Multi attribute is not provided"
    end
  end

end