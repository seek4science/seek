class SampleControlledVocab < ApplicationRecord
  include Seek::UrlValidation

  has_many :sample_controlled_vocab_terms, inverse_of: :sample_controlled_vocab,
                                           after_add: :update_sample_type_templates,
                                           after_remove: :update_sample_type_templates,
                                           dependent: :destroy
  has_many :sample_attributes, inverse_of: :sample_controlled_vocab
  has_many :extended_metadata_attributes, inverse_of: :sample_controlled_vocab
  has_many :template_attributes, inverse_of: :sample_controlled_vocab

  has_many :sample_types, through: :sample_attributes
  has_many :samples, through: :sample_types
  belongs_to :repository_standard, inverse_of: :sample_controlled_vocabs

  auto_strip_attributes :ols_root_term_uris

  validates :title, presence: true, uniqueness: true
  validates :key, uniqueness: { allow_blank: true }
  validate :validate_ols_root_term_uris

  accepts_nested_attributes_for :sample_controlled_vocab_terms, allow_destroy: true
  accepts_nested_attributes_for :repository_standard, reject_if: :check_repository_standard

  grouped_pagination

  def labels
    sample_controlled_vocab_terms.collect(&:label)
  end

  def includes_term?(value)
    labels.include?(value)
  end

  def can_delete?(user = User.current_user)
    sample_types.empty? && can_edit?(user)
  end

  def can_edit?(user = User.current_user)
    return false unless Seek::Config.samples_enabled
    return false unless user
    return true if user.is_admin?

    !system_vocab? && samples.empty? && (!Seek::Config.project_admin_sample_type_restriction || user.is_admin_or_project_administrator?)
  end

  # a vocabulary that is built in and seeded, and that other parts are dependent upon
  def system_vocab?
    # currently determined by whether it has a special key, which cannot be set by user defined CV's
    key.present? && SystemVocabs.database_key_known?(key)
  end

  def self.can_create?
    # criteria is the same, and likely to always be
    SampleType.can_create?
  end

  # whether the controlled vocab is linked to an ontology
  def ontology_based?
    source_ontology.present? && ols_root_term_uris.present?
  end

  def validate_ols_root_term_uris
    return if self.ols_root_term_uris.blank?
    uris = self.ols_root_term_uris.split(',').collect(&:strip).reject(&:blank?)
    uris.each do |uri|
      unless valid_url?(uri)
        errors.add(:ols_root_term_uris, "invalid URI - #{uri}")
        return false
      end
    end
    self.ols_root_term_uris = uris.join(', ')
  end

  # updates the vocab and terms from a json file created with rake seek_dev:dump_controlled_vocab
  def update_from_json_dump(json, delete_removed)
    # find and attach the ids for those that exist
    presented_iris = []
    json[:sample_controlled_vocab_terms_attributes].each do |term_json|
      iri = term_json[:iri]
      presented_iris << iri
      term = sample_controlled_vocab_terms.where(iri: iri).first
      if term
        term_json[:id] = term.id
      end
    end

    existing_iris = sample_controlled_vocab_terms.select(:iri).collect(&:iri)
    removed_iris = existing_iris - presented_iris
    removed_iris.each do |iri|
      term = sample_controlled_vocab_terms.where(iri: iri).first

      # see if the label exists, and if so set id to update existing or otherwise mark for deletion. (deleting original and adding new will give duplicate label validation error)
      json_term = json[:sample_controlled_vocab_terms_attributes].detect{|json_term| json_term[:label] == term.label}
      if json_term
        json_term[:id] = term.id
      elsif delete_removed
        json[:sample_controlled_vocab_terms_attributes] << {id: term.id, _destroy:true }
      end

    end
    update(json)
  end

  private

  def update_sample_type_templates(_term)
    sample_types.each(&:queue_template_generation) unless new_record?
  end



  class SystemVocabs
    # property -> database key
    MAPPING = {
      topics: 'topic_annotations',
      operations: 'operation_annotations',
      data_formats: 'data_format_annotations',
      data_types: 'data_type_annotations',
      disciplines: 'discipline_annotations',
      sop_types: 'sop_type_annotations'
    }

    def self.vocab_for_property(property)
      SampleControlledVocab.find_by_key(database_key_for_property(property))
    end

    def self.database_key_for_property(property)
      raise 'Invalid property' unless valid_properties.include?(property)

      MAPPING[property]
    end

    def self.valid_properties
      MAPPING.keys
    end

    def self.database_key_known?(key)
      MAPPING.values.include?(key)
    end

    MAPPING.each_key do |property|
      define_singleton_method "#{property}_controlled_vocab" do
        vocab_for_property(property)
      end
    end
  end
end
