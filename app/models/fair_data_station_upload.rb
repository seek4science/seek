class FairDataStationUpload < ApplicationRecord
  belongs_to :investigation
  belongs_to :content_blob, validate: true
  belongs_to :project
  belongs_to :policy, validate: true
  belongs_to :contributor, class_name: 'Person'
  enum :purpose, %i[import update], suffix: true

  validates :contributor, :content_blob, :purpose, presence: true
  validate :validate_project_membership
  validate :validate_can_manage_investigation
  validate :validate_for_purpose

  has_task :import
  has_task :update

  scope :for_project_and_contributor, ->(project, contributor) { where project: project, contributor: contributor }
  scope :for_investigation_and_contributor, lambda { |investigation, contributor|
    where investigation: investigation, contributor: contributor
  }

  scope :show_status, -> { where show_status: true }

  def self.matching_imports_in_progress(project, external_id)
    FairDataStationUpload.import_purpose
                         .joins(:import_task)
                         .where(investigation_external_identifier: external_id,
                                project: project,
                                tasks: { status: [Task::STATUS_QUEUED, Task::STATUS_ACTIVE, Task::STATUS_WAITING] })
  end

  def self.matching_updates_in_progress(investigation, external_id)
    FairDataStationUpload.update_purpose
                         .joins(:update_task)
                         .where(investigation_external_identifier: external_id,
                                investigation: investigation,
                                tasks: { status: [Task::STATUS_QUEUED, Task::STATUS_ACTIVE, Task::STATUS_WAITING] })
  end

  private

  def validate_project_membership
    return if project.nil? || contributor&.member_of?(project)

    errors.add(:contributor, "must be a member of the #{I18n.t('project')}")
  end

  def validate_can_manage_investigation
    return if investigation.nil? || investigation.can_manage?(contributor)

    errors.add(:contributor, "must be able to manage the #{I18n.t('investigation')}")
  end

  def validate_for_purpose
    errors.add(:project, 'must not be blank for an import') if import_purpose? && project.blank?
    return unless update_purpose?
    return unless investigation.blank?

    errors.add(:investigation, 'must not be blank for an update')
  end
end
