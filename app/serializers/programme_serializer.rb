class ProgrammeSerializer < AvatarObjSerializer
  attributes :title, :description,
             # :web_page,
             :funding_details

  self.attribute(:web_page)
  attribute :tags do
    serialize_annotations(object, context='funding_code')
  end

end
