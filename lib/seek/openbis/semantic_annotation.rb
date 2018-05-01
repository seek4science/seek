module Seek
  module Openbis
    # Represents SemanticAnnotation from OBIS
    class SemanticAnnotation
      attr_accessor :predicateOntologyId, :predicateOntologyVersion, :predicateAccessionId,
                    :descriptorOntologyId, :descriptorOntologyVersion, :descriptorAccessionId
    end
  end
end
