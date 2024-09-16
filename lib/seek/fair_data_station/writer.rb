module Seek
  module FairDataStation
    class Writer
      def construct_isa(datastation_inv, contributor, projects, policy)
        reset_data_file_cache
        investigation = build_investigation(datastation_inv, contributor, projects, policy)

        datastation_inv.studies.each do |datastation_study|
          study = build_study(datastation_study, contributor, policy, investigation)
          datastation_study.observation_units.each do |datastation_observation_unit|
            observation_unit = build_observation_unit(datastation_observation_unit, contributor, projects, policy,
                                                      study)
            datastation_observation_unit.samples.each do |datastation_sample|
              sample = build_sample(datastation_sample, contributor, projects, policy)
              if sample.valid?
                observation_unit.samples << sample
              else
                Rails.logger.error("Invalid sample during fair data station import #{sample.errors.full_messages.inspect}")
              end
              datastation_sample.assays.each do |datastation_assay|
                build_assay(datastation_assay, contributor, projects, policy, sample, study)
              end
            end
          end
        end

        investigation
      end

      def update_isa(investigation, datastation_inv, contributor, projects, policy)
        reset_data_file_cache
        update_investigation(investigation, datastation_inv, contributor, projects, policy)
        datastation_inv.studies.each do |datastation_study|
          study = update_or_build_study(datastation_study, contributor, projects, policy, investigation)
        end

        investigation
      end

      private

      def reset_data_file_cache
        @data_file_cache = {}
      end

      def build_assay(datastation_assay, contributor, projects, policy, sample, study)
        samples = []
        samples << sample if sample.valid?
        assay_attributes = datastation_assay.seek_attributes.merge({ contributor: contributor, study: study,
                                                                     assay_class: AssayClass.experimental, samples: samples, policy: policy.deep_copy })
        assay = study.assays.build(assay_attributes)
        populate_extended_metadata(assay, datastation_assay)
        datastation_assay.datasets.each do |datastation_dataset|
          df = build_data_file(contributor, datastation_dataset, projects, policy)
          assay.assay_assets.build(asset: df)
        end
        assay
      end

      def build_sample(datastation_sample, contributor, projects, policy)
        sample_attributes = datastation_sample.seek_attributes.merge({ contributor: contributor, projects: projects,
                                                                       policy: policy.deep_copy })
        sample = ::Sample.new(sample_attributes)
        populate_sample(sample, datastation_sample)
        sample
      end

      def build_observation_unit(datastation_observation_unit, contributor, projects, policy, study)
        observation_unit_attributes = datastation_observation_unit.seek_attributes.merge({ contributor: contributor,
                                                                                           study: study, projects: projects, policy: policy.deep_copy })
        observation_unit = study.observation_units.build(observation_unit_attributes)
        datastation_observation_unit.datasets.each do |datastation_dataset|
          df = build_data_file(contributor, datastation_dataset, projects, policy)
          observation_unit.observation_unit_assets.build(asset: df)
        end
        populate_extended_metadata(observation_unit, datastation_observation_unit)
        observation_unit
      end

      def build_study(datastation_study, contributor, policy, investigation)
        study_attributes = datastation_study.seek_attributes.merge({ contributor: contributor,
                                                                     investigation: investigation, policy: policy.deep_copy })
        study = investigation.studies.build(study_attributes)
        populate_extended_metadata(study, datastation_study)
        study
      end

      def build_investigation(datastation_inv, contributor, projects, policy)
        inv_attributes = datastation_inv.seek_attributes.merge({ contributor: contributor, projects: projects,
                                                                 policy: policy.deep_copy })
        investigation = ::Investigation.new(inv_attributes)
        populate_extended_metadata(investigation, datastation_inv)
        investigation
      end

      def update_investigation(investigation, datastation_inv, contributor, projects, policy)
        inv_attributes = datastation_inv.seek_attributes
        investigation.update(inv_attributes)
        update_extended_metadata(investigation, datastation_inv)
        investigation
      end

      def update_study(study, datastation_study, contributor, projects, policy)
        study_attributes = datastation_study.seek_attributes
        study.update(study_attributes)
        update_extended_metadata(study, datastation_study)
        study
      end

      def update_or_build_study(datastation_study, contributor, projects, policy, investigation)
        study = ::Study.by_external_identifier(datastation_study.external_id, projects)
        if study
          update_study(study, datastation_study, contributor, projects, policy)
          investigation.studies << study
        else
          study = build_study(datastation_study, contributor, policy, investigation)
        end
        study
      end

      def populate_extended_metadata(seek_entity, datastation_entity)
        if emt = detect_extended_metadata(seek_entity, datastation_entity)
          seek_entity.extended_metadata = ExtendedMetadata.new(extended_metadata_type: emt)
          update_extended_metadata(seek_entity, datastation_entity)
        end
      end

      def update_extended_metadata(seek_entity, datastation_entity)
        datastation_entity.populate_extended_metadata(seek_entity)
      end

      def detect_extended_metadata(seek_entity, datastation_entity)
        property_ids = datastation_entity.additional_metadata_annotations.collect { |annotation| annotation[0] }

        # collect and sort those with the most properties that match, eliminating any where no properties match
        candidates = ExtendedMetadataType.where(supported_type: seek_entity.class.name).includes(:extended_metadata_attributes).collect do |emt|
          ids = emt.extended_metadata_attributes.collect(&:pid)
          score = (property_ids - ids).length
          emt = nil if (property_ids & ids).empty?
          [score, emt]
        end.sort_by do |x|
          x[0]
        end

        candidates.first&.last
      end

      def populate_sample(seek_sample, datastation_sample)
        if sample_type = detect_sample_type(datastation_sample)
          seek_sample.sample_type = sample_type
          datastation_sample.populate_seek_sample(seek_sample)
          seek_sample.set_attribute_value('Title', datastation_sample.title)
          seek_sample.set_attribute_value('Description', datastation_sample.description)
        end
      end

      def detect_sample_type(datastation_sample)
        property_ids = datastation_sample.additional_metadata_annotations.collect { |annotation| annotation[0] }

        # collect and sort those with the most properties that match, eliminating any where no properties match
        candidates = SampleType.all.collect do |sample_type|
          ids = sample_type.sample_attributes.collect(&:pid)
          score = (property_ids - ids).length
          sample_type = nil if (property_ids & ids).empty?
          [score, sample_type]
        end.sort_by { |x| x[0] }

        candidates.first&.last
      end

      def build_data_file(contributor, datastation_dataset, projects, policy)
        @data_file_cache[datastation_dataset.identifier] ||= begin
          blob = ContentBlob.new(url: datastation_dataset.content_url.to_s,
                                 original_filename: datastation_dataset.identifier, external_link: true, is_webpage: true, content_type: 'application/octet-stream')
          data_file_attributes = datastation_dataset.seek_attributes.merge({
                                                                             contributor: contributor, projects: projects,
                                                                             content_blob: blob, policy: policy.deep_copy
                                                                           })
          DataFile.new(data_file_attributes)
        end
      end
    end
  end
end
