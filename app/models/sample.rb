class Sample < ActiveRecord::Base
  # attr_accessible :contributor_id, :contributor_type, :json_metadata,
  #                :policy_id, :sample_type_id, :sample_type, :title, :uuid, :project_ids, :policy, :contributor,
  #                :other_creators, :data

  searchable(auto_index: false) do
    text :attribute_values do
      attribute_values_for_search
    end
    text :sample_type do
      sample_type.title
    end
  end if Seek::Config.solr_enabled

  acts_as_asset

  belongs_to :sample_type, inverse_of: :samples
  belongs_to :originating_data_file, class_name: 'DataFile'
  has_many :sample_resource_links, dependent: :destroy
  has_many :strains, through: :sample_resource_links, source: :resource, source_type: 'Strain'
  has_many :organisms, through: :strains

  scope :default_order, -> { order('title') }

  validates :title, :sample_type, presence: true
  include ActiveModel::Validations
  validates_with SampleAttributeValidator

  before_validation :update_json_metadata
  before_validation :set_title_to_title_attribute_value

  before_save :update_sample_strain_links
  after_save :queue_sample_type_update_job
  after_destroy :queue_sample_type_update_job

  def sample_type=(type)
    super
    @data = Seek::Samples::SampleData.new(type)
    update_json_metadata
    type
  end

  def is_in_isa_publishable?
    false
  end

  def self.can_create?
    User.logged_in_and_member? && Seek::Config.samples_enabled
  end

  def self.user_creatable?
    true
  end

  def related_data_file
    originating_data_file
  end

  def related_samples
    samples_this_links_to
  end

  # Mass assignment of attributes
  def data=(hash)
    data.mass_assign(hash)
  end

  def data
    @data ||= Seek::Samples::SampleData.new(sample_type, json_metadata)
  end

  def referenced_strains
    sample_type.sample_attributes.select { |sa| sa.sample_attribute_type.base_type == Seek::Samples::BaseType::SEEK_STRAIN }.map do |sa|
      value = get_attribute(sa.hash_key)
      Strain.find_by_id(value['id']) if value
    end.compact
  end

  def get_attribute(attr)
    data[attr]
  end

  def set_attribute(attr, value)
    data[attr] = value
  end

  def blank_attribute?(attr)
    data[attr].blank? || (data[attr].respond_to?(:values) && data[attr].values.all?(&:blank?))
  end

  def state_allows_edit?(*args)
    (id.nil? || originating_data_file.nil?) && super
  end

  def extracted?
    !!originating_data_file
  end

  def projects
    extracted? ? originating_data_file.projects : super
  end

  def project_ids
    extracted? ? originating_data_file.project_ids : super
  end

  def creators
    extracted? ? originating_data_file.creators : super
  end

  private

  def samples_this_links_to
    return [] unless sample_type
    seek_sample_attributes = sample_type.sample_attributes.select { |attr| attr.sample_attribute_type.seek_sample? }
    seek_sample_attributes.map { |attr| Sample.find_by_id(get_attribute(attr.hash_key)) }.compact
  end

  def attribute_values_for_search
    sample_type ? data.values.select { |v| !v.blank? }.uniq : []
  end

  # override to insert the extra accessors for mass assignment
  def mass_assignment_authorizer(role)
    extra = []
    extra = sample_type.sample_attributes.collect(&:method_name) if sample_type
    super(role) + extra
  end

  def update_json_metadata
    self.json_metadata = data.to_json
  end

  def set_title_to_title_attribute_value
    attr = title_attribute
    if attr
      value = get_attribute(title_attribute.hash_key)
      if attr.seek_strain?
        value = value[:title]
      elsif attr.seek_sample?
        value = Sample.find_by_id(value).try(:title)
      else
        value = value.to_s
      end
      self.title = value
    end
  end

  # the designated title attribute
  def title_attribute
    return nil unless sample_type && sample_type.sample_attributes.title_attributes.any?
    sample_type.sample_attributes.title_attributes.first
  end

  def respond_to_missing?(method_name, include_private = false)
    name = method_name.to_s
    if name.start_with?(SampleAttribute::METHOD_PREFIX) &&
       data.key?(name.sub(SampleAttribute::METHOD_PREFIX, '').chomp('='))
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

  def queue_sample_type_update_job
    SampleTypeUpdateJob.new(sample_type, false).queue_job
  end

  def update_sample_strain_links
    self.strains = referenced_strains
  end
end
