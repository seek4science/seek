module Git
  class BlobSerializer < ActiveModel::Serializer
    include Rails.application.routes.url_helpers

    attributes :id, :path, :size, :binary, :content, :annotations

    def id
      object.oid
    end

    def binary
      object.binary?
    end

    def content
      Base64.encode64(object.file_contents)
    end

    def annotations
      object.annotations.map { |a| { key: a.key, value: a.value } }
    end
  end
end
