class ContributedResourceSerializer < PCSSerializer
  attributes :title, :description, :version, :license
  attribute :latest_version do
    if object.latest_version.nil?
      latest = {}
    else
      latest = { title: object.latest_version.title,
               description: object.latest_version.description,
               version: object.latest_version.version,
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

  attribute :content_blobs do
    blobs = []
    if defined?(object.content_blobs)
      object.content_blobs.each do |cb|
        blobs.append(make_cb_attribute(cb))
      end
    elsif defined?(object.content_blob)
      blobs.append(make_cb_attribute(object.content_blob))
     # blobs.append(object.content_blob)
    end
    blobs
  end

  #leaving out asset_id, asset_type, asset_version, sha1sum, md5sum
  def make_cb_attribute(cb)
    {
        content_blob_id: cb.id.to_s,
        original_filename: cb.original_filename,
        content_type: cb.content_type,
        is_webpage: cb.is_webpage,
        external_link: cb.external_link,
        file_size: cb.file_size,
        url: cb.url,
        uuid: cb.uuid
    }
  end
end
