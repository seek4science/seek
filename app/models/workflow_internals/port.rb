module WorkflowInternals
  class Port < Part
    FORMALPARAMETER_PROFILE = 'https://bioschemas.org/profiles/FormalParameter/1.0-RELEASE/'.freeze

    attr_reader :structure, :id, :name, :description, :format

    def initialize(structure, id: nil, name: nil, description: nil, type: nil, format: nil)
      super(structure, id: id)
      @name = name
      @description = description
      @type = type
      @format = format
    end

    def type
      if @type.is_a?(Array)
        @type.without('null')
      else
        @type
      end
    end

    def optional?
      @type.is_a?(Array) && @type.include?('null')
    end

    def ro_crate_metadata
      {
        "@type": 'FormalParameter',
        "@id": ROCrate::ContextualEntity.format_local_id("#{workflow&.title || 'dummy'}-#{self.class.name.demodulize.underscore.pluralize}-#{id}"),
        name: name || id,
        "dct:conformsTo": FORMALPARAMETER_PROFILE
      }
    end
  end
end
