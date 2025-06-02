class FairDataStationUpload < ApplicationRecord
  belongs_to :investigation
  belongs_to :content_blob
  belongs_to :project
  belongs_to :policy
  belongs_to :contributor, class_name: 'Person'
  enum :purpose, %i[import update], suffix: true

  validates :contributor, :content_blob, :project, :purpose, presence: true
  validate :validate_project_membership

  has_task :import
  has_task :update

  scope :for_project_and_contributor, ->(project, contributor) { where project: project, contributor: contributor }
  scope :show_status, -> { where show_status: true}

  def self.matching_imports_in_progress(project, external_id)
    FairDataStationUpload.import_purpose.where(investigation_external_identifier: external_id,
                                               project: project).select do |upload|
      upload.import_task.in_progress? || upload.import_task.waiting?
    end
  end

  def self.matching_updates_in_progress(project, external_id)
    FairDataStationUpload.update_purpose.where(investigation_external_identifier: external_id,
                                               project: project).select do |upload|
      upload.update_task.in_progress? || upload.update_task.waiting?
    end
  end

  private

  def validate_project_membership
    return if contributor&.member_of?(project)

    errors.add("must be a member of the #{t('project')}")
  end
end
