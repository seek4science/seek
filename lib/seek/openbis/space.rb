module Seek
  module Openbis
    class Space < Entity
      attr_accessor :description

      def populate_from_json(json)
        @description = json['description'] || ''
        super(json)
      end

      def type_name
        'Space'
      end
    end
  end
end
