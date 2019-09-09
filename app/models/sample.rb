class Sample < ApplicationRecord
  include Seek::Rdf::RdfGeneration

  searchable(auto_index: false) do
    text :attribute_values do
      attribute_values_for_search
    end
    text :sample_type do
      sample_type.title
    end
  end if Seek::Config.solr_enabled


  acts_as_asset

  validates :projects, presence: true, projects: { self: true }

  belongs_to :sample_type, inverse_of: :samples
  belongs_to :originating_data_file, class_name: 'DataFile'

  has_many :sample_resource_links, inverse_of: :sample, dependent: :destroy
  has_many :reverse_sample_resource_links, inverse_of: :resource, class_name: 'SampleResourceLink', as: :resource, dependent: :destroy

  has_many :strains, through: :sample_resource_links, source: :resource, source_type: 'Strain'
  has_many :organisms, through: :strains

  has_many :linked_samples, through: :sample_resource_links, source: :resource, source_type: 'Sample'
  has_many :linking_samples, through: :reverse_sample_resource_links, source: :sample

  validates :title, :sample_type, presence: true
  include ActiveModel::Validations
  validates_with SampleAttributeValidator

  before_validation :update_json_metadata
  before_validation :set_title_to_title_attribute_value

  before_save :update_sample_resource_links
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
    Sample.where(id: related_sample_ids)
  end

  def related_sample_ids
    linked_sample_ids | linking_sample_ids
  end

  # Mass assignment of attributes
  def data=(hash)
    data.mass_assign(hash)
  end

  def data
    @data ||= Seek::Samples::SampleData.new(sample_type, json_metadata)
  end

  def referenced_resources
    sample_type.sample_attributes.select(&:seek_resource?).map do |sa|
      value = get_attribute(sa)
      type = sa.sample_attribute_type.base_type_handler.type
      type.constantize.find_by_id(value['id']) if value && type
    end.compact
  end

  def referenced_strains
    referenced_resources.select { |r| r.is_a?(Strain) }
  end

  def referenced_samples
    referenced_resources.select { |r| r.is_a?(Sample) }
  end

  def get_attribute(attr)
    attr = attr.accessor_name if attr.is_a?(SampleAttribute)

    data[attr]
  end

  def set_attribute(attr, value)
    attr = attr.accessor_name if attr.is_a?(SampleAttribute)

    data[attr] = value
  end

  def blank_attribute?(attr)
    attr = attr.accessor_name if attr.is_a?(SampleAttribute)

    data[attr].blank? || (data[attr].is_a?(Hash) && data[attr]['id'].blank? && data[attr]['title'].blank?)
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

  def title_from_data
    attr = title_attribute
    if attr
      value = get_attribute(title_attribute)
      if attr.seek_resource?
        value[:title] || value[:id]
      else
        value.to_s
      end
    else
      nil
    end
  end

  # although it includes the RdfGeneration for some rdf support, it can't be considered to fully support it yet.
  def rdf_supported?
    false
  end

  def related_organisms
    Organism.where(id: related_organism_ids)
  end

  def related_organism_ids
    organism_ids | ncbi_linked_organisms.map(&:id)
  end

  private

  # organisms linked through an NCBI attribute type
  def ncbi_linked_organisms
    return [] unless sample_type
    Rails.cache.fetch("sample-organisms-#{cache_key}-#{Organism.order('updated_at DESC').first.try(:cache_key)}") do
      sample_type.sample_attributes.collect do |attribute|
        next unless attribute.sample_attribute_type.title == 'NCBI ID'
        value = get_attribute(attribute)
        if value
          Organism.all.select { |o| o.ncbi_id && o.ncbi_id.to_s == value }
        end
      end.flatten.compact.uniq
    end
  end

  def samples_this_links_to
    return [] unless sample_type
    seek_sample_attributes = sample_type.sample_attributes.select { |attr| attr.sample_attribute_type.seek_sample? }
    seek_sample_attributes.map do |attr|
      value = get_attribute(attr)
      Sample.find_by_id(value['id']) if value
    end.compact
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
    self.title = title_from_data
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

  def update_sample_resource_links
    self.strains = referenced_strains
    self.linked_samples = referenced_samples
  end
end
