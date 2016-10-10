class SampleControlledVocab < ActiveRecord::Base
  attr_accessible :title, :description, :sample_controlled_vocab_terms_attributes

  has_many :sample_controlled_vocab_terms, inverse_of: :sample_controlled_vocab,
           after_add: :update_sample_type_templates,
           after_remove: :update_sample_type_templates,
           dependent: :destroy
  has_many :sample_attributes, inverse_of: :sample_controlled_vocab
  has_many :sample_types, through: :sample_attributes
  has_many :samples, through: :sample_types

  validates :title, presence: true, uniqueness: true

  accepts_nested_attributes_for :sample_controlled_vocab_terms, allow_destroy: true

  grouped_pagination

  def labels
    sample_controlled_vocab_terms.collect(&:label)
  end

  def includes_term?(value)
    labels.include?(value)
  end

  def can_delete?(_user = User.current_user)
    sample_types.empty?
  end

  def can_edit?(_user = User.current_user)
    samples.empty?
  end

  def self.can_create?
    User.logged_in_and_member? && Seek::Config.samples_enabled
  end

  private

  def update_sample_type_templates(term)
    unless new_record?
      sample_types.each(&:queue_template_generation)
    end
  end

end
