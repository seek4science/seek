class ProgrammeSerializer < AvatarObjSerializer
  attributes :title, :description,
             :web_page, :funding_details
  attribute :tags do
    serialize_annotations(object, context='funding_code')
  end
end
