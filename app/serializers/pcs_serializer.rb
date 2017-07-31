class PCSSerializer < BaseSerializer
  has_many :creators, include_data:true
  has_one :submitter, include_data:true do
    determine_submitter object
  end
  has_one :policy, include_data:true
  attribute :tags do
    serialize_annotations(object)
  end
end
