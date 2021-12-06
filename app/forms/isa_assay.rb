class IsaAssay
  include ActiveModel::Model
  
  attr_accessor :assay, :sample_type, :input_sample_type_id

  validates_presence_of :assay, :sample_type, :input_sample_type_id
  validate :validate_objects

  def initialize (params = {})
    @assay = Assay.new(params[:assay]||{})
    @sample_type = SampleType.new((params[:sample_type]||{}).merge({project_ids: @assay.project_ids}))
    @sample_type.sample_attributes.build(is_title: true, required: true) if !params[:sample_type]
    @assay.sample_type = @sample_type
    @assay.assay_class = AssayClass.for_type("experimental")
    @input_sample_type_id = params[:input_sample_type_id]
  end


  def save
    if valid?
      # connect the sample type multi link attribute to the last sample type of the assay's study
      @sample_type.sample_attributes.detect {|a| a.seek_sample_multi?}.linked_sample_type_id = @input_sample_type_id
      @assay.save
      @sample_type.save
    else
      false
    end
  end

  def assay
    @assay
  end

  def sample_type
    @sample_type
  end

  def can_manage?
    false
  end

  private

  def validate_objects
    @assay.errors.each {|e| errors[:base] << "[Assay]: #{e}" } if !@assay.valid?
    errors[:base] << "SOP is required" if @assay.sop_ids.blank?

    if !@sample_type.valid?
      @sample_type.errors.full_messages.each {|e| errors[:base] << "[Sample type]: #{e}"} 
    end

    if !@sample_type.sample_attributes.any? {|a| a.seek_sample_multi?}
      errors[:base] << "[Sample type]: SEEK Sample Multi attribute is not provided"
    end

    if @input_sample_type_id.blank?
      errors[:base] << "[Input Assay]: Input Assay is not provided"
    end
  end

end