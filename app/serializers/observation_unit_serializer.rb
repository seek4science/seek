class ObservationUnitSerializer < ContributedResourceSerializer
  has_many :people
  has_many :projects
  has_one :study
  has_many :samples
  has_many :data_files
end
