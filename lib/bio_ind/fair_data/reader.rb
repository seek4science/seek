require 'rdf'
require 'rdf/turtle'
require 'sparql/client'

module BioInd
  module FairData
    class Reader

      def self.parse_graph(path)
        graph = RDF::Graph.load(path, format: :ttl)
        sparql = SPARQL::Client.new(graph)
        jerm = RDF::Vocabulary.new('http://jermontology.org/ontology/JERMOntology#')

        query = sparql.select.where(
          [:inv, RDF.type, jerm.[]('Investigation')]
        )
        query.execute.collect do |inv|
          inv = BioInd::FairData::Investigation.new(inv.inv, graph)
          inv.populate
          inv
        end
      end

      def self.construct_isa(datastation_inv, contributor, projects)
        inv_attributes = datastation_inv.seek_attributes.merge({contributor: contributor, projects: projects})
        investigation = ::Investigation.new(inv_attributes)
        populate_extended_metadata(investigation, datastation_inv)

        datastation_inv.studies.each do |datastation_study|
          study_attributes = datastation_study.seek_attributes.merge({contributor: contributor, investigation: investigation})
          study = investigation.studies.build(study_attributes)
          populate_extended_metadata(study, datastation_study)
          datastation_study.assays.each do |datastation_assay|
            assay_attributes = datastation_assay.seek_attributes.merge({contributor: contributor, study:study, assay_class: AssayClass.experimental})
            assay = study.assays.build(assay_attributes)
            populate_extended_metadata(assay, datastation_assay)
            datastation_assay.datasets.each do |datastation_dataset|
              blob = ContentBlob.new(url: datastation_dataset.resource_uri.to_s, original_filename: datastation_dataset.identifier )
              data_file_attributes = datastation_dataset.seek_attributes.merge({
                                                                                 contributor: contributor, projects: projects,
                                                                                 content_blob: blob
                                                                               })
              df = DataFile.new(data_file_attributes)
              assay.assay_assets.build(asset: df)
            end
          end
        end

        return investigation
      end

      def self.populate_extended_metadata(seek_entity, datastation_entity)
        if emt = detect_extended_metadata(seek_entity, datastation_entity)
          seek_entity.extended_metadata = ExtendedMetadata.new(extended_metadata_type: emt)
          datastation_entity.populate_extended_metadata(seek_entity)
        end
      end

      def self.detect_extended_metadata(seek_entity, datastation_entity)
        property_ids = datastation_entity.additional_metadata_annotations.collect{|annotation| annotation[0]}

        # collect and sort those with the most properties that match, eliminating any where no properties match
        candidates = ExtendedMetadataType.where(supported_type: seek_entity.class.name).includes(:extended_metadata_attributes).collect do |emt|
          ids = emt.extended_metadata_attributes.collect(&:property_type_id)
          score = (property_ids - ids).length
          emt = nil if (property_ids & ids).empty?
          [score, emt]
        end.sort_by{|x| x[0]}

        candidates.first&.last
      end

    end
  end
end
