class Sample < ActiveRecord::Base
  attr_accessible :contributor_id, :contributor_type, :json_metadata,
                  :policy_id, :sample_type_id, :sample_type, :title, :uuid, :project_ids, :policy, :contributor,
                  :other_creators, :data

  searchable(:auto_index=>false) do
    text :attribute_values do
      attribute_values_for_search
    end
    text :sample_type do
      sample_type.title
    end
  end if Seek::Config.solr_enabled

  acts_as_asset

  belongs_to :sample_type, inverse_of: :samples
  belongs_to :originating_data_file, :class_name => 'DataFile'

  scope :default_order, order("title")

  validates :title, :sample_type, presence: true
  include ActiveModel::Validations
  validates_with SampleAttributeValidator

  before_save :set_json_metadata
  before_validation :set_title_to_title_attribute_value

  def sample_type=(type)
    super
    self.json_metadata = nil
    @data = nil
  end

  def is_in_isa_publishable?
    false
  end

  def self.can_create?
    User.logged_in_and_member?
  end


  def self.user_creatable?
    true
  end

  def related_data_file
    originating_data_file
  end

  # Mass assignment of attributes
  def data= hash
    hash.each do |key, value|
      set_attribute(key, value)
    end
  end

  def data
    if @data.blank?
      if json_metadata.blank?
        if sample_type.nil?
          @data = HashWithIndifferentAccess.new
        else
          @data = JSON.parse(set_json_structure).with_indifferent_access
        end
      else
        @data = JSON.parse(json_metadata).with_indifferent_access
      end
    else
      @data
    end
  end

  def strains
    self.sample_type.sample_attributes.select { |sa| sa.sample_attribute_type.base_type == 'SeekStrain' }.map do |sa|
      Strain.find_by_id(get_attribute(sa.hash_key)['id'])
    end.compact
  end

  def get_attribute(attr)
    data[attr]
  end

  def set_attribute(attr, value)
    data[attr] = attribute_for_attribute_name(attr).pre_process_value(value)
  end

  private

  def attribute_values_for_search
    return [] unless self.sample_type
    self.sample_type.sample_attributes.collect do |attr|
      self.data[attr.hash_key].to_s
    end.reject{|val| val.blank?}.uniq
  end

  # override to insert the extra accessors for mass assignment
  def mass_assignment_authorizer(role)
    extra = []
    if sample_type
      extra = sample_type.sample_attributes.collect(&:method_name)
    end
    super(role) + extra
  end

  def set_json_metadata
    self.json_metadata = @data.to_json
  end

  # Creates a JSON skeleton with null values in the json_metadata field
  def set_json_structure
    hash = Hash[sample_type.sample_attributes.map do |attribute|
      [attribute.hash_key, nil]
    end]
    self.json_metadata = hash.to_json
  end

  def set_title_to_title_attribute_value
    self.title = title_attribute_value
  end

  #the value of the designated title attribute
  def title_attribute_value
    return nil unless (sample_type && sample_type.sample_attributes.title_attributes.any?)
    title_attr=sample_type.sample_attributes.title_attributes.first
    get_attribute(title_attr.hash_key)
  end

  def respond_to_missing?(method_name, include_private = false)
    if data.key?(method_name.to_s.sub(SampleAttribute::METHOD_PREFIX,'').chomp('='))
      true
    else
      super
    end
  end

  def method_missing(method_name, *args)
    name = method_name.to_s
    if name.start_with?(SampleAttribute::METHOD_PREFIX)
      setter = name.end_with?('=')
      attribute_name = name.sub(SampleAttribute::METHOD_PREFIX, '').chomp('=')
      if data.key?(attribute_name)
        set_attribute(attribute_name, args.first) if setter
        get_attribute(attribute_name)
      else
        super
      end
    else
      super
    end
  end

  def attribute_for_attribute_name(attribute_name)
    sample_type.sample_attributes.where(accessor_name:attribute_name).first
  end

end
