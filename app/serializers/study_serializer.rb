class StudySerializer < SnapshottableSerializer
  attributes :title, :description, :experimentalists, :other_creators, :position
  attribute :person_responsible_id do
    object.person_responsible_id.to_s
  end

  has_many :people
  has_many :projects
  has_one :investigation
  has_many :assays
  has_many :data_files
  has_many :models
  has_many :sops
  has_many :publications
  has_many :documents
end
