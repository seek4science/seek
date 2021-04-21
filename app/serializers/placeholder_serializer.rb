class PlaceholderSerializer < PCSSerializer
  attributes :title, :description, :license, :created_at, :updated_at, :other_creators

  attribute :tags do
    serialize_annotations(object)
  end

  has_many :people
  has_many :projects
  has_many :assays
  has_one :file_template

  attribute :data_type
  attribute :format_type

  def self_link
    polymorphic_path(object)
  end

end
