class SampleType < ApplicationRecord
  # attr_accessible :title, :uuid, :sample_attributes_attributes,
 #                 :description, :uploaded_template, :project_ids, :tags

  searchable(auto_index: false) do
    text :attribute_search_terms
  end if Seek::Config.solr_enabled

  include Seek::ActsAsAsset::Searching
  include Seek::Search::BackgroundReindexing

  include Seek::ProjectAssociation

  # everything concerned with sample type templates
  include Seek::Templates::SampleTypeTemplateConcerns

  include Seek::Annotatable

  include Seek::Permissions::SpecialContributors

  acts_as_uniquely_identifiable

  acts_as_favouritable

  has_many :samples, inverse_of: :sample_type

  has_many :sample_attributes, -> { order(:pos) }, inverse_of: :sample_type, dependent: :destroy, after_add: :detect_link_back_to_self

  has_many :linked_sample_attributes, class_name: 'SampleAttribute', foreign_key: 'linked_sample_type_id'

  belongs_to :contributor, class_name: 'Person'

  validates :title, presence: true
  validates :title, length: { maximum: 255 }
  validates :description, length: { maximum: 65_535 }
  validates :contributor, presence: true

  validate :validate_one_title_attribute_present, :validate_attribute_title_unique

  validates :projects, presence: true, projects: { self: true }

  accepts_nested_attributes_for :sample_attributes, allow_destroy: true

  grouped_pagination

  has_annotation_type :sample_type_tag, method_name: :tags

  def validate_value?(attribute_name, value)
    attribute = sample_attributes.detect { |attr| attr.title == attribute_name }
    fail UnknownAttributeException.new("Unknown attribute #{attribute_name}") unless attribute
    attribute.validate_value?(value)
  end

  def contributors
    [contributor]
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
    true
  end

  def self.can_create?
    can = User.logged_in_and_member? && Seek::Config.samples_enabled
    can && (!Seek::Config.project_admin_sample_type_restriction || User.current_user.is_admin_or_project_administrator?)
  end

  def can_edit?(user = User.current_user)
    return false if user.nil? || user.person.nil? || !Seek::Config.samples_enabled
    return true if user.is_admin?
    contributor == user.person || projects.detect { |project| project.can_be_administered_by?(user)}.present?
  end

  def can_delete?(user = User.current_user)
    can_edit?(user) && samples.empty? &&
      linked_sample_attributes.detect do|attr|
        attr.sample_type &&
          attr.sample_type != self
      end.nil?
  end

  def can_view?(user = User.current_user, referring_sample = nil)
    project_membership = (user && user.person && (user.person.projects & projects).any?)
    project_membership || public_samples? || check_referring_sample_permission(user,referring_sample)
  end

  def editing_constraints
    Seek::Samples::SampleTypeEditingConstraints.new(self)
  end

  private

  # whether the referring sample is valid and gives permission to view
  def check_referring_sample_permission(user,referring_sample)
    referring_sample.try(:sample_type)==self && referring_sample.can_view?(user)
  end

  #whether it is assocaited with any public samples
  def public_samples?
    samples.joins(:policy).where('policies.access_type >= ?',Policy::VISIBLE).any?
  end

  # fixes the consistency of the attribute controlled vocabs where the attribute doesn't match.
  # this is to help when a controlled vocab has been selected in the form, but then the type has been changed
  # rather than clearing the selected vocab each time
  def resolve_controlled_vocabs_inconsistencies
    sample_attributes.each do |attribute|
      attribute.sample_controlled_vocab = nil unless attribute.controlled_vocab?
    end
  end

  # fixes the consistency of the attribute seek samples where the attribute doesn't match.
  # this is to help when a seek sample has been selected in the form, but then the type has been changed
  # rather than clearing the selected sample type each time
  def resolve_seek_samples_inconsistencies
    sample_attributes.each do |attribute|
      attribute.linked_sample_type = nil unless attribute.seek_sample?
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
      dups_text=dups.join(', ')
      errors.add(:sample_attributes, "Attribute names must be unique, there are duplicates of #{dups_text}")
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

  class UnknownAttributeException < Exception; end
end
