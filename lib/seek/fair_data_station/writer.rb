module Seek
  module FairDataStation
    class ExternalIdMismatchException < RuntimeError; end;
    class Writer
      def construct_isa(datastation_inv, contributor, projects, policy)
        reset_data_file_cache
        investigation = build_investigation(datastation_inv, contributor, projects, policy)

        datastation_inv.studies.each do |datastation_study|
          study = build_study(datastation_study, contributor, policy, investigation)
          datastation_study.observation_units.each do |datastation_observation_unit|
            observation_unit = build_observation_unit(datastation_observation_unit, contributor, policy, study)
            datastation_observation_unit.samples.each do |datastation_sample|
              sample = build_sample(datastation_sample, contributor, projects, policy, observation_unit)
              datastation_sample.assays.each do |datastation_assay|
                build_assay(datastation_assay, contributor, projects, policy, sample, study)
              end
            end
          end
        end

        investigation
      end

      def update_isa(investigation, datastation_inv, contributor, projects, policy)
        unless investigation.external_identifier == datastation_inv.external_id
          raise ExternalIdMismatchException.new('Investigation external identifiers do not match')
        end

        preload_data_file_cache(investigation.related_data_files)
        update_entity(investigation, datastation_inv, contributor, projects, policy)
        datastation_inv.studies.each do |datastation_study|
          study = update_or_build_study(datastation_study, contributor, projects, policy, investigation)
          datastation_study.observation_units.each do |datastation_observation_unit|
            observation_unit = update_or_build_observation_unit(datastation_observation_unit, contributor, projects,
                                                                policy, study)
            datastation_observation_unit.samples.each do |datastation_sample|
              sample = update_or_build_sample(datastation_sample, contributor, projects, policy, observation_unit)
              datastation_sample.assays.each do |datastation_assay|
                update_or_build_assay(datastation_assay, contributor, projects, policy, sample, study)
              end
            end
          end
        end

        investigation
      end

      private

      def reset_data_file_cache
        @data_file_cache = {}
      end

      def preload_data_file_cache(data_files)
        reset_data_file_cache
        data_files.each do |data_file|
          @data_file_cache[data_file.external_identifier] = data_file
        end
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

      def build_sample(datastation_sample, contributor, projects, policy, observation_unit)
        sample_attributes = datastation_sample.seek_attributes.merge({ contributor: contributor, projects: projects,
                                                                       policy: policy.deep_copy })
        sample = observation_unit.samples.build(sample_attributes)
        populate_sample(sample, datastation_sample)
        sample
      end

      def build_observation_unit(datastation_observation_unit, contributor, policy, study)
        observation_unit_attributes = datastation_observation_unit.seek_attributes.merge({ contributor: contributor,
                                                                                           study: study, projects: projects, policy: policy.deep_copy })
        observation_unit = study.observation_units.build(observation_unit_attributes)
        datastation_observation_unit.datasets.each do |datastation_dataset|
          df = build_data_file(contributor, datastation_dataset, study.projects, policy)
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

      def update_entity(seek_entity, datastation_entity, _contributor, _projects, _policy)
        attributes = datastation_entity.seek_attributes
        seek_entity.assign_attributes(attributes)
        update_extended_metadata(seek_entity, datastation_entity)
        seek_entity
      end

      def update_sample(seek_sample, datastation_sample, _contributor, _projects, _policy)
        sample_attributes = datastation_sample.seek_attributes
        seek_sample.assign_attributes(sample_attributes)
        populate_sample(seek_sample, datastation_sample)
        seek_sample
      end

      def update_or_build_study(datastation_study, contributor, projects, policy, investigation)
        study = ::Study.by_external_identifier(datastation_study.external_id, projects)
        if study
          update_entity(study, datastation_study, contributor, projects, policy)
          study.observation_units = []
          investigation.studies << study
        else
          study = build_study(datastation_study, contributor, policy, investigation)
        end
        study
      end

      def update_or_build_observation_unit(datastation_observation_unit, contributor, projects, policy, study)
        observation_unit = ::ObservationUnit.by_external_identifier(datastation_observation_unit.external_id, projects)
        if observation_unit
          update_entity(observation_unit, datastation_observation_unit, contributor, projects, policy)
          observation_unit.study = study
          observation_unit.observation_unit_assets.delete_all
          datastation_observation_unit.datasets.each do |datastation_dataset|
            df = build_data_file(contributor, datastation_dataset, projects, policy)
            observation_unit.observation_unit_assets.build(asset: df)
          end
          observation_unit.samples = []
          study.observation_units << observation_unit
        else
          observation_unit = build_observation_unit(datastation_observation_unit, contributor, projects, policy, study)
        end
        observation_unit
      end

      def update_or_build_sample(datastation_sample, contributor, projects, policy, observation_unit)
        sample = ::Sample.by_external_identifier(datastation_sample.external_id, projects)
        if sample
          update_sample(sample, datastation_sample, contributor, projects, policy)
          sample.observation_unit = observation_unit
          sample.assays = []
          observation_unit.samples << sample
        else
          sample = build_sample(datastation_sample, contributor, projects, policy, observation_unit)
        end
        sample
      end

      def update_or_build_assay(datastation_assay, contributor, projects, policy, sample, study)
        assay = ::Assay.by_external_identifier(datastation_assay.external_id, projects)
        if assay
          update_entity(assay, datastation_assay, contributor, projects, policy)
          assay.samples = [sample]
          assay.assay_assets.where(asset_type: 'DataFile').delete_all
          datastation_assay.datasets.each do |datastation_dataset|
            df = build_data_file(contributor, datastation_dataset, projects, policy)
            assay.assay_assets.build(asset: df)
          end
          study.assays << assay
        else
          build_assay(datastation_assay, contributor, projects, policy, sample, study)
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
        candidates = ::ExtendedMetadataType.where(supported_type: seek_entity.class.name).includes(:extended_metadata_attributes).collect do |emt|
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
        @data_file_cache[datastation_dataset.external_id] ||= begin
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
