module Seek
  module Openbis
    # Behaviour relevant to a content blob that represents and openbis entity
    # FIXME: wanted to call ContentBlob but rails loader didn't like it and got confused over the model ContentBlob disregarding the namespacing. Need to investigate why?
    module Blob

      def is_openbis?
        url && URI.parse(url).scheme=='openbis' && url.split(':').count==4
      end

      def openbis_dataset
        return nil unless is_openbis?
        parts = url.split(':')
        endpoint=OpenbisEndpoint.find(parts[1])
        endpoint.space #temporarily needed to authenticate
        Seek::Openbis::Dataset.new(parts[3])
      end



    end
  end
end