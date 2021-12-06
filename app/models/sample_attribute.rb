class SampleAttribute < ApplicationRecord
  include Seek::JSONMetadata::Attribute

  belongs_to :sample_type, inverse_of: :sample_attributes
  belongs_to :unit

  belongs_to :linked_sample_type, class_name: 'SampleType'

  validates :sample_type, presence: true
  validates :pid, format: { with: URI::regexp, allow_blank: true, allow_nil: true, message: 'not a valid URI' }

  before_save :store_accessor_name
  before_save :default_pos, :force_required_when_is_title

  scope :title_attributes, -> { where(is_title: true) }

  # to store that this attribute should be linked to the sample_type it is being assigned to, but needs to wait until the
  # sample type exists
  attr_reader :deferred_link_to_self

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

end
