class FairDataStationUpload < ApplicationRecord
  belongs_to :investigation
  belongs_to :content_blob
  belongs_to :project
  belongs_to :contributor, class_name: 'Person'
  enum :purpose,  [:import, :update], suffix: true

  validates :contributor, :content_blob, :project, :purpose, presence: true
  validate :validate_project_membership

  has_task :fair_data_station_import
  has_task :fair_data_station_update


  private

  def validate_project_membership
    unless contributor&.member_of?(project)
      errors.add("must be a member of the #{t('project')}")
    end
  end



end
