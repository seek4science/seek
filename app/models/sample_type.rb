class SampleType < ActiveRecord::Base
  attr_accessible :title, :uuid, :sample_attributes_attributes

  acts_as_uniquely_identifiable

  has_many :samples

  has_many :sample_attributes, order: :pos, inverse_of: :sample_type

  belongs_to :content_blob
  alias_method :template, :content_blob

  validates :title, presence: true
  validate :validate_one_title_attribute_present, :validate_template_file

  accepts_nested_attributes_for :sample_attributes, allow_destroy: true

  def validate_value?(attribute_name, value)
    attribute = sample_attributes.detect { |attr| attr.title == attribute_name }
    fail UnknownAttributeException.new("Unknown attribute #{attribute_name}") if attribute.nil?
    attribute.validate_value?(value)
  end

  def build_from_template
    return unless compatible_template_file?

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

  def self.sample_types_matching_content_blob(content_blob)
    SampleType.all.select do |type|
      type.matches_content_blob?(content_blob)
    end
  end

  def build_samples_from_template(content_blob)
    samples = []
    columns = sample_attributes.collect(&:template_column_index)
    columns_and_attributes = Hash[sample_attributes.collect { |attr| [attr.template_column_index, attr] }]
    handler = Seek::Templates::SamplesHandler.new(content_blob)
    handler.each_record(columns) do |_row, data|
      sample = Sample.new(sample_type: self)
      data.each do |entry|
        if attribute = columns_and_attributes[entry.column]
          sample.send("#{attribute.accessor_name}=", entry.value)
        end
      end
      samples << sample
    end
    samples
  end

  def matches_content_blob?(blob)
    other_handler = Seek::Templates::SamplesHandler.new(blob)
    compatible_template_file? && other_handler.compatible? && (template_handler.column_details == other_handler.column_details)
  end

  private

  def template_handler
    @template_handler ||= Seek::Templates::SamplesHandler.new(content_blob)
  end

  def default_attribute_type
    SampleAttributeType.primitive_string_types.first
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

  class UnknownAttributeException < Exception; end
end
