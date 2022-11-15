module Git
  class TreeSerializer < ActiveModel::Serializer
    include Rails.application.routes.url_helpers

    attributes :id, :path, :tree

    def id
      object.oid
    end

    def tree
      object.each.map do |entry|
        {
          id: entry[:oid],
          name: entry[:name],
          type: entry[:type],
          path: object.absolute_path(entry[:name]),
          mode: entry[:filemode].to_s(8).rjust(6, '0')
        }
      end
    end
  end
end
