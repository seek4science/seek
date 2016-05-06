class SampleType < ActiveRecord::Base
  attr_accessible :title, :uuid, :sample_attributes_attributes


  searchable(:auto_index=>false) do
    text :attribute_search_terms
  end if Seek::Config.solr_enabled

  include Seek::ActsAsAsset::Searching
  include Seek::Search::BackgroundReindexing

  acts_as_uniquely_identifiable

  has_many :samples, inverse_of: :sample_type

  has_many :sample_attributes, order: :pos, inverse_of: :sample_type, dependent: :destroy

  has_one :content_blob, :as => :asset, dependent: :destroy

  alias_method :template, :content_blob

  validates :title, presence: true

  validate :validate_one_title_attribute_present, :validate_template_file, :validate_attribute_title_unique

  accepts_nested_attributes_for :sample_attributes, allow_destroy: true

  def self.can_create?
    User.logged_in_and_member?
  end

  def validate_value?(attribute_name, value)
    attribute = sample_attributes.detect { |attr| attr.title == attribute_name }
    fail UnknownAttributeException.new("Unknown attribute #{attribute_name}") if attribute.nil?
    attribute.validate_value?(value)
  end

  def build_attributes_from_template
    unless compatible_template_file?
      errors.add(:base, "Invalid spreadsheet - Couldn't find a 'samples' sheet")
      return
    end

    template_handler.column_details.each do |details|
      is_title = sample_attributes.empty?
      sample_attributes << SampleAttribute.new(title: details.label,
                                               sample_attribute_type: default_attribute_type,
                                               is_title: is_title,
                                               required: is_title,
                                               template_column_index: details.column)
    end
  end

  def compatible_template_file?
    template_handler.compatible?
  end

  def matches_content_blob?(blob)
    return false unless template
    Rails.cache.fetch("st-match-#{blob.id}-#{content_blob.id}") do
      other_handler = Seek::Templates::SamplesHandler.new(blob)
      compatible_template_file? && other_handler.compatible? && (template_handler.column_details == other_handler.column_details)
    end
  end

  def self.sample_types_matching_content_blob(content_blob)
    SampleType.all.select do |type|
      type.matches_content_blob?(content_blob)
    end
  end

  def build_samples_from_template(content_blob)
    samples = []
    columns = sample_attributes.collect(&:template_column_index)

    handler = Seek::Templates::SamplesHandler.new(content_blob)
    handler.each_record(columns) do |_row, data|
      samples << build_sample_from_template_data(data)
    end
    samples
  end

  def can_download?
    true
  end

  def self.user_creatable?
    true
  end

  #FIXME: these are just here to satisfy the Searchable module, as a quick fix
  def assay_type_titles
    []
  end

  def technology_type_titles
    []
  end

  private

  #required by Seek::ActsAsAsset::Searching - don't really need to full search terms, including content provided by Seek::ActsAsAsset::ContentBlobs
  # just the filename
  def content_blob_search_terms
    if content_blob
      [content_blob.original_filename]
    else
      []
    end
  end

  def build_sample_from_template_data(data)
    sample = Sample.new(sample_type: self)
    data.each do |entry|
      if attribute = attribute_for_column(entry.column)
        sample.set_attribute(attribute.hash_key, entry.value)
      end
    end
    sample
  end

  def attribute_for_column(column)
    @columns_and_attributes ||= Hash[sample_attributes.collect { |attr| [attr.template_column_index, attr] }]
    @columns_and_attributes[column]
  end

  def template_handler
    @template_handler ||= Seek::Templates::SamplesHandler.new(content_blob)
  end

  def default_attribute_type
    SampleAttributeType.default
  end

  def validate_one_title_attribute_present
    unless (count = sample_attributes.select(&:is_title).count) == 1
      errors.add(:sample_attributes, "There must be 1 attribute which is the title, currently there are #{count}")
    end
  end

  def validate_template_file
    if template && !compatible_template_file?
      errors.add(:template, 'Not a valid template file')
    end
  end

  def validate_attribute_title_unique
    # TODO: would like to have done this with uniquness{scope: :sample_type_id} on the attribute, but that leads to an exception when being added
    # to the sample type
    titles = sample_attributes.collect(&:title).collect(&:downcase)
    dups = titles.select { |title| titles.count(title) > 1 }.uniq
    unless dups.empty?
      errors.add(:sample_attributes, "Attribute names must be unique, there are duplicates of #{dups.join(', ')}")
    end
  end

  def attribute_search_terms
    sample_attributes.collect(&:title)
  end

  class UnknownAttributeException < Exception; end
end
