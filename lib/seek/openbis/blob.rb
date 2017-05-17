module Seek
  module Openbis
    # Behaviour relevant to a content blob that represents and openbis entity
    # FIXME: wanted to call ContentBlob but rails loader didn't like it and got confused
    # ... over the model ContentBlob disregarding the namespacing. Need to investigate why?
    module Blob
      # NOTE: the fact is it prepended rather than included seems to prevent the use of Concern's which
      # doesn't handle prepend
      def self.prepended(base)
        base.class_eval do
          scope :for_openbis_endpoint, (->(endpoint) { where("url LIKE 'openbis:#{endpoint.id}%'") })
        end
      end

      def openbis?
        url && valid_url? && URI.parse(url).scheme == 'openbis' && url.split(':').count == 4
      end

      def openbis_dataset
        return nil unless openbis?
        parts = url.split(':')
        endpoint = OpenbisEndpoint.find(parts[1])
        Seek::Openbis::Dataset.new(endpoint, parts[3])
      end

      def search_terms
        super | openbis_search_terms
      end

      # overide and ignore the url
      def url_search_terms
        if openbis?
          []
        else
          super
        end
      end

      private

      def openbis_search_terms
        return [] unless openbis? && (dataset = openbis_dataset)
        terms = [dataset.perm_id, dataset.dataset_type_code, dataset.dataset_type_description,
                 dataset.experiment_id, dataset.registrator, dataset.modifier, dataset.code]
        terms | dataset.dataset_files_no_directories.collect do |file|
          [file.perm_id, file.path, file.filename]
        end.flatten.uniq
      end
    end
  end
end
