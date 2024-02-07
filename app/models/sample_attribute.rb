class SampleAttribute < ApplicationRecord
  include Seek::JSONMetadata::Attribute

  belongs_to :sample_type, inverse_of: :sample_attributes
  belongs_to :unit

  belongs_to :linked_sample_type, class_name: 'SampleType'

  belongs_to :isa_tag

  auto_strip_attributes :pid
  validates :sample_type, presence: true
  validates :pid, format: { with: URI::regexp, allow_blank: true, allow_nil: true, message: 'not a valid URI' }
  validate :validate_against_editing_constraints, if: -> { sample_type.present? }

  before_save :store_accessor_name
  before_save :default_pos, :force_required_when_is_title

  scope :title_attributes, -> { where(is_title: true) }

  # to store that this attribute should be linked to the sample_type it is being assigned to, but needs to wait until the
  # sample type exists
  attr_reader :deferred_link_to_self

  # whether this attribute is tied to a controlled vocab which is based on an ontology
  delegate :ontology_based?, to: :sample_controlled_vocab, allow_nil: true

  def input_attribute?
    isa_tag.nil? && title.downcase.include?('input') && seek_sample_multi?
  end

  def title=(title)
    super
    store_accessor_name
    self.title
  end

  def linked_sample_type_id=(id)
    @deferred_link_to_self = true if id == 'self'
    super(id)
  end

  def required?
    super || is_title?
  end

  def controlled_vocab_labels
    if controlled_vocab?
      sample_controlled_vocab.labels
    else
      []
    end
  end

  # provides the hash that defines the column definition for template generation
  def template_column_definition
    { title.to_s => controlled_vocab_labels }
  end

  def short_pid
    return '' unless pid.present?
    URI.parse(pid).fragment || pid.gsub(/.*\//,'') || pid
  end

  def linked_extended_metadata_type
    nil
  end

  private

  def store_accessor_name
    self.original_accessor_name = accessor_name
  end

  # if not set, takes the next value for that sample type
  def default_pos
    self.pos ||= (self.class.where(sample_type_id: sample_type_id).maximum(:pos) || 0) + 1
  end

  def force_required_when_is_title
    # forces required to be true if it is a title
    self.required = required? || is_title?
    true
  end

  def validate_against_editing_constraints
    c = sample_type.editing_constraints
    error_message = "cannot be changed (#{title_was})" # Use pre-change title in error message.

    errors.add(:title, error_message) if title_changed? && !c.allow_name_change?(self)

    unless c.allow_required?(self)
      errors.add(:is_title, error_message) if is_title_changed?
      errors.add(:required, error_message) if required_changed?
    end

    unless c.allow_type_change?(self)
      errors.add(:sample_attribute_type, error_message) if sample_attribute_type_id_changed?
      errors.add(:sample_controlled_vocab, error_message) if sample_controlled_vocab_id_changed?
      errors.add(:linked_sample_type, error_message) if linked_sample_type_id_changed?
      errors.add(:unit, error_message) if unit_id_changed?
    end
  end
end
