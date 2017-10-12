class PCSSerializer < BaseSerializer
  has_many :creators
  has_many :submitter # set seems to be one way of doing optional

  def submitter
    result = determine_submitter object
    if result.blank?
      return []
    else
      return [result]
    end
  end

  attribute :tags do
    serialize_annotations(object)
  end
end
