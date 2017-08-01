class ContributedResourceSerializer < PCSSerializer
  attributes :title, :description, :version

  attribute :latest_version do
    if object.latest_version.nil?
      latest = {}
    else
      latest = { title: object.latest_version.title,
               description: object.latest_version.description,
               revision_comments: object.latest_version.revision_comments,
               # template_id: object.latest_version.template_id         #  ==>  only in DataFile
               # template_name: object.latest_version.template_name,
               # is_with_sample: object.latest_version.is_with_sample,
               # doi: object.latest_version.doi,                        #  ==> does not exist in presentation
               license: object.latest_version.license,
               uuid: object.latest_version.uuid,
               created_at: object.latest_version.created_at,
               updated_at: object.latest_version.updated_at
             }
    end

    latest
  end
  
  has_one :content_blob, include_data:true
  has_many :versions, include_data:true , include_links:true do
    object.versions
  end
end
