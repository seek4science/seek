class SampleType < ApplicationRecord
  # attr_accessible :title, :uuid, :sample_attributes_attributes,
  #                 :description, :uploaded_template, :project_ids, :tags

  if Seek::Config.solr_enabled
    searchable(auto_index: false) do
      text :attribute_search_terms
    end
  end

  include Seek::ActsAsAsset::Searching
  include Seek::Search::BackgroundReindexing
  include Seek::Stats::ActivityCounts
  include Seek::Creators

  include Seek::ProjectAssociation

  # everything concerned with sample type templates
  include Seek::Templates::SampleTypeTemplateConcerns

  include Seek::Annotatable

  include Seek::Permissions::SpecialContributors

  acts_as_uniquely_identifiable

  acts_as_favouritable

  has_many :samples, inverse_of: :sample_type

  has_filter :contributor

  has_many :sample_attributes, -> { order(:pos) }, inverse_of: :sample_type, dependent: :destroy, after_add: :detect_link_back_to_self
  alias_method :metadata_attributes, :sample_attributes

  has_many :linked_sample_attributes, class_name: 'SampleAttribute', foreign_key: 'linked_sample_type_id'

  belongs_to :contributor, class_name: 'Person'
  belongs_to :isa_template, class_name: 'Template', foreign_key: 'template_id'

  has_many :assays
  has_and_belongs_to_many :studies

  scope :without_template, -> { where(template_id: nil) }

  validates :title, presence: true
  validates :title, length: { maximum: 255 }
  validates :description, length: { maximum: 65_535 }
  validates :contributor, presence: true
  validate :validate_one_title_attribute_present,
           :validate_attribute_title_unique,
           :validate_attribute_accessor_names_unique,
           :validate_title_is_not_type_of_seek_sample_multi,
           :validate_against_editing_constraints
  validates :projects, presence: true, projects: { self: true }

  accepts_nested_attributes_for :sample_attributes, allow_destroy: true

  grouped_pagination

  has_annotation_type :sample_type_tag, method_name: :tags

  def is_isa_json_compliant?
    studies.any? || assays.any?
  end

  def validate_value?(attribute_name, value)
    attribute = sample_attributes.detect { |attr| attr.title == attribute_name }
    raise UnknownAttributeException, "Unknown attribute #{attribute_name}" unless attribute
    attribute.validate_value?(value)
  end

  def contributors
    [contributor]
  end

  def related_templates
    [isa_template].compact
  end

  # refreshes existing samples following a change to the sample type. For example when changing the title field
  def refresh_samples
    Sample.record_timestamps = false
    # prevent a job being created when the sample is saved
    Sample.skip_callback :save, :after, :queue_sample_type_update_job
    begin
      disable_authorization_checks do
        samples.each(&:save)
      end
    ensure
      Sample.record_timestamps = true
      Sample.set_callback :save, :after, :queue_sample_type_update_job
    end
  end

  # fixes inconsistencies following form submission that could cause validation errors
  # in particular removing linked controlled vocabs or seek_samples after the attribute type may have changed
  def resolve_inconsistencies
    resolve_controlled_vocabs_inconsistencies
    resolve_seek_samples_inconsistencies
  end

  def can_download?(user = User.current_user)
    can_view?(user)
  end

  def self.user_creatable?
    Sample.user_creatable?
  end

  def self.can_create?
    can = User.logged_in_and_member? && Seek::Config.samples_enabled
    can && (!Seek::Config.project_admin_sample_type_restriction || User.current_user.is_admin_or_project_administrator?)
  end

  def can_edit?(user = User.current_user)
    return false if user.nil? || user.person.nil? || !Seek::Config.samples_enabled
    return true if user.is_admin?
    contributor == user.person || projects.detect { |project| project.can_manage?(user) }.present?
  end

  def can_delete?(user = User.current_user)
    can_edit?(user) && samples.empty? &&
      linked_sample_attributes.detect do |attr|
        attr.sample_type &&
          attr.sample_type != self
      end.nil?
  end

  def can_view?(user = User.current_user, referring_sample = nil, view_in_single_page = false)
    return false if Seek::Config.isa_json_compliance_enabled && template_id.present? && !view_in_single_page

    project_membership = user&.person && (user.person.projects & projects).any?
    is_creator = creators.include?(user&.person)
    project_membership || public_samples? || is_creator || check_referring_sample_permission(user, referring_sample)
  end

  def editing_constraints
    Seek::Samples::SampleTypeEditingConstraints.new(self)
  end

  def contributing_user
    contributor&.user
  end

  def can_see_hidden_item?(user)
    can_view?(user)
  end

  private

  # whether the referring sample is valid and gives permission to view
  def check_referring_sample_permission(user, referring_sample)
    referring_sample.try(:sample_type) == self && referring_sample.can_view?(user)
  end

  # whether it is assocaited with any public samples
  def public_samples?
    samples.joins(:policy).where('policies.access_type >= ?', Policy::VISIBLE).any?
  end

  # fixes the consistency of the attribute controlled vocabs where the attribute doesn't match.
  # this is to help when a controlled vocab has been selected in the form, but then the type has been changed
  # rather than clearing the selected vocab each time
  def resolve_controlled_vocabs_inconsistencies
    sample_attributes.each do |attribute|
      attribute.sample_controlled_vocab = nil unless attribute.controlled_vocab? || attribute.seek_cv_list?
    end
  end

  # fixes the consistency of the attribute seek samples where the attribute doesn't match.
  # this is to help when a seek sample has been selected in the form, but then the type has been changed
  # rather than clearing the selected sample type each time
  def resolve_seek_samples_inconsistencies
    sample_attributes.each do |attribute|
      attribute.linked_sample_type = nil unless attribute.seek_sample? || attribute.seek_sample_multi?
    end
  end

  def validate_one_title_attribute_present
    unless (count = sample_attributes.select(&:is_title).count) == 1
      errors.add(:sample_attributes, "There must be 1 attribute which is the title, currently there are #{count}")
    end
  end

  def validate_attribute_title_unique
    # TODO: would like to have done this with uniquness{scope: :sample_type_id} on the attribute, but that leads to an exception when being added
    # to the sample type
    titles = attribute_titles.collect(&:downcase)
    dups = titles.select { |title| titles.count(title) > 1 }.uniq
    if dups.any?
      dups_text = dups.join(', ')
      errors.add(:sample_attributes, "Attribute names must be unique, there are duplicates of #{dups_text}")
    end
  end

  def validate_attribute_accessor_names_unique
    groups = sample_attributes.to_a.group_by(&:accessor_name)
    dups = groups.select { |_k, v| v.length > 1 }
    if dups.any?
      dups_text = dups.map { |_k, v| "(#{v.map(&:title).join(', ')})" }.join(', ')
      errors.add(:sample_attributes, "Attribute names are too similar: #{dups_text}")
    end
  end

  def validate_against_editing_constraints
    c = editing_constraints
    sample_attributes.each do |a|
      if a.marked_for_destruction? && !c.allow_attribute_removal?(a)
        errors.add(:sample_attributes, "cannot be removed, there are existing samples using this attribute (#{a.title})")
      end

      if a.new_record? && !c.allow_new_attribute?
        errors.add(:sample_attributes, "cannot be added, new attributes are not allowed (#{a.title})")
      end
    end
  end

  def attribute_search_terms
    attribute_titles
  end

  def attribute_titles
    sample_attributes.collect(&:title)
  end

  # callback when the attribute is added to the sample type. it can now be linked to this sample type now we know what it is
  def detect_link_back_to_self(sample_attribute)
    if sample_attribute.deferred_link_to_self
      sample_attribute.linked_sample_type = self
    end
  end

  def validate_title_is_not_type_of_seek_sample_multi
    base_type = Seek::Samples::BaseType::SEEK_SAMPLE_MULTI
    is_title_seek_sample_multi = sample_attributes.find(&:is_title)&.sample_attribute_type&.base_type == base_type
    if is_title_seek_sample_multi
      errors.add(:sample_attributes, "Attribute type of #{base_type.underscore.humanize} can not be selected as the sample type title.")
    end
  end

  class UnknownAttributeException < RuntimeError; end
end
