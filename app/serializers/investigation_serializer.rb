class InvestigationSerializer < SnapshottableSerializer
  attributes :title, :description, :other_creators, :position
  attributes :started_at, :finished_at, :status

  has_many :people
  has_many :projects
  has_many :studies
  has_many :assays
  has_many :data_files
  has_many :models
  has_many :sops
  has_many :publications
  has_many :documents
  has_one :assignee
end
