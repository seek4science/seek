class Sample < ApplicationRecord
  include Seek::Rdf::RdfGeneration
  include Seek::BioSchema::Support
  include Seek::JSONMetadata::Serialization

  if Seek::Config.solr_enabled
    searchable(auto_index: false) do
      text :attribute_values do
        attribute_values_for_search
      end
      text :sample_type do
        sample_type.title
      end
    end
  end

  acts_as_asset

  belongs_to :sample_type, inverse_of: :samples
  alias_method :metadata_type, :sample_type

  belongs_to :originating_data_file, class_name: 'DataFile'

  has_many :sample_resource_links, inverse_of: :sample, dependent: :destroy
  has_many :reverse_sample_resource_links, inverse_of: :resource, class_name: 'SampleResourceLink', as: :resource, dependent: :destroy

  has_many :strains, through: :sample_resource_links, source: :resource, source_type: 'Strain'
  has_many :organisms, through: :strains

  has_many :linked_samples, through: :sample_resource_links, source: :resource, source_type: 'Sample'
  has_many :linking_samples, through: :reverse_sample_resource_links, source: :sample

  has_many :linked_data_files, through: :sample_resource_links, source: :resource, source_type: 'DataFile'
  has_many :linked_sops, through: :sample_resource_links, source: :resource, source_type: 'Sop'

  belongs_to :observation_unit

  validates :projects, presence: true, projects: { self: true }
  validates :title, :sample_type, presence: true

  validates_with SampleAttributeValidator
  validate :validate_added_linked_sample_permissions
  validate :check_if_locked_sample_type, on: %i[create update]

  before_validation :set_title_to_title_attribute_value
  before_validation :update_sample_resource_links

  after_save :queue_sample_type_update_job
  after_save :queue_linking_samples_update_job
  after_destroy :queue_sample_type_update_job

  has_filter :sample_type

  def sample_type=(type)
    super
    @data = Seek::JSONMetadata::Data.new(type)
    update_json_metadata
    type
  end

  def is_in_isa_publishable?
    false
  end

  def self.can_create?
    User.logged_in_and_member? && Seek::Config.samples_enabled
  end

  def self.supports_extended_metadata?
    false
  end

  def related_data_files
    [originating_data_file].compact + linked_data_files
  end

  def related_sops
    linked_sops
  end

  def related_samples
    Sample.where(id: related_sample_ids)
  end

  def related_sample_ids
    linked_sample_ids | linking_sample_ids
  end

  def referenced_resources
    sample_type.sample_attributes.select(&:seek_resource?).map do |sa|
      value = get_attribute_value(sa)
      type = sa.base_type_handler.type
      return [] unless type
      Array.wrap(value).map { |v| type.find_by_id(v['id']) if v }
    end.flatten.compact
  end

  def referenced_data_files
    referenced_resources.select { |r| r.is_a?(DataFile) }
  end

  def referenced_sops
    referenced_resources.select { |r| r.is_a?(Sop) }
  end

  def referenced_strains
    referenced_resources.select { |r| r.is_a?(Strain) }
  end

  def referenced_samples
    referenced_resources.select { |r| r.is_a?(Sample) }
  end

  def extracted?
    !!originating_data_file
  end

  def creators
    extracted? ? originating_data_file.creators : super
  end

  def title_from_data
    attr = title_attribute
    if attr
      value = get_attribute_value(title_attribute)
      if attr.seek_resource?
        value[:title] || value[:id]
      else
        value.to_s
      end
    end
  end

  def related_organisms
    Organism.where(id: related_organism_ids)
  end

  def related_organism_ids
    organism_ids | ncbi_linked_organisms.map(&:id)
  end

  # overides default to include sample_type key at the start
  def list_item_title_cache_key_prefix
    "#{sample_type.list_item_title_cache_key_prefix}/#{cache_key}"
  end

  def refresh_linking_samples
    linking_samples.group_by(&:sample_type).each do |sample_type, _linking_samples|
      potential_linking_attributes = sample_type.sample_attributes.select do |sa|
        sa.seek_sample_multi? || sa.seek_sample?
      end

      _linking_samples.each do |linking_sample|
        changed = false
        potential_linking_attributes.each do |attr|
          Array(linking_sample.get_attribute_value(attr)).each do |linked_sample_data|
            next unless linked_sample_data['id'] == id
            next if linked_sample_data['title'] == title
            linked_sample_data['title'] = title
            changed = true
          end
        end
        linking_sample.update_column(:json_metadata, linking_sample.data.to_json) if changed
      end
    end
  end

  private

  # organisms linked through an NCBI attribute type
  def ncbi_linked_organisms
    return [] unless sample_type

    Rails.cache.fetch("sample-organisms-#{cache_key}-#{Organism.order('updated_at DESC').first.try(:cache_key)}") do
      sample_type.sample_attributes.collect do |attribute|
        next unless attribute.sample_attribute_type.title == 'NCBI ID'

        value = get_attribute_value(attribute)
        Organism.all.select { |o| o.ncbi_id && o.ncbi_id.to_s == value } if value
      end.flatten.compact.uniq
    end
  end

  def samples_this_links_to
    return [] unless sample_type

    seek_sample_attributes = sample_type.sample_attributes.select { |attr| attr.sample_attribute_type.seek_sample? }
    seek_sample_attributes.map do |attr|
      value = get_attribute_value(attr)
      Sample.find_by_id(value['id']) if value
    end.compact
  end

  def attribute_values_for_search
    sample_type ? data.values.reject(&:blank?).uniq : []
  end

  def set_title_to_title_attribute_value
    self.title = title_from_data
  end

  # the designated title attribute
  def title_attribute
    return nil unless sample_type && sample_type.sample_attributes.title_attributes.any?

    sample_type.sample_attributes.title_attributes.first
  end

  def queue_sample_type_update_job
    SampleTypeUpdateJob.new(sample_type, false).queue_job
  end

  def queue_linking_samples_update_job
    LinkingSamplesUpdateJob.new(self).queue_job if saved_change_to_title?
  end

  def update_sample_resource_links
    return unless sample_type.present?
    self.strains = referenced_strains
    self.linked_samples = referenced_samples
    self.linked_data_files = referenced_data_files
    self.linked_sops = referenced_sops
  end

  def attribute_class
    SampleAttribute
  end

  # checks and validates whether new linked samples have view permission, but ignores existing ones
  def validate_added_linked_sample_permissions
    return if $authorization_checks_disabled
    return if linked_samples.empty?
    previous_linked_samples = []
    previous_linked_samples = Sample.find(id).referenced_samples unless new_record?
    additions = linked_samples - previous_linked_samples
    errors.add(:linked_samples, 'includes a new private sample') if additions.detect { |sample| !sample.can_view? }
  end

  def check_if_locked_sample_type
    errors.add(:sample_type, 'is locked') if sample_type&.locked?
  end
end
