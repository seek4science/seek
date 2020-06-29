class AssaySerializer < SnapshottableSerializer
  attributes :title, :description, :other_creators
  attribute :assay_class do
    { title: object.assay_class.title,
      key: object.assay_class.key,
      description: object.assay_class.description }
  end

  attribute :assay_type do
    { label:  object.assay_type_label,
      uri: object.assay_type_uri }
  end

  attribute :technology_type do
    { label: object.technology_type_label,
      uri: object.technology_type_uri }
  end

  attribute :tags do
    serialize_annotations(object, context = 'tag')
  end

  has_many :organisms
  has_many :human_diseases
  # has_many :assay_organisms

  has_many :people
  has_many :projects
  has_one :investigation
  has_one :study
  has_many :data_files
  has_many :models
  has_many :sops
  has_many :publications
  has_many :documents
end
