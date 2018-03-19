class PCSSerializer < BaseSerializer
  has_many :creators
  has_many :submitter # set seems to be one way of doing optional

  attribute :tags do
    serialize_annotations(object)
  end
end
