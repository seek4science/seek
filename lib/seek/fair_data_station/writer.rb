module Seek
  module FairDataStation
    class ExternalIdMismatchException < RuntimeError; end
    class MissingSampleTypeException < RuntimeError; end

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
          raise ExternalIdMismatchException, 'Investigation external identifiers do not match'
        end

        preload_data_file_cache(investigation.related_data_files)
        update_entity(investigation, datastation_inv, contributor)
        datastation_inv.studies.each do |datastation_study|
          study = update_or_build_study(datastation_study, contributor, projects, policy, investigation)
          datastation_study.observation_units.each do |datastation_observation_unit|
            observation_unit = update_or_build_observation_unit(datastation_observation_unit, contributor, policy,
                                                                study)
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
        record_activity(assay, contributor, 'create')
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
        record_activity(sample, contributor, 'create')
        sample
      end

      def build_observation_unit(datastation_observation_unit, contributor, policy, study)
        observation_unit_attributes = datastation_observation_unit.seek_attributes.merge({ contributor: contributor,
                                                                                           study: study, policy: policy.deep_copy })
        observation_unit = study.observation_units.build(observation_unit_attributes)
        datastation_observation_unit.datasets.each do |datastation_dataset|
          df = build_data_file(contributor, datastation_dataset, study.projects, policy)
          observation_unit.observation_unit_assets.build(asset: df)
        end
        populate_extended_metadata(observation_unit, datastation_observation_unit)
        record_activity(observation_unit, contributor, 'create')
        observation_unit
      end

      def build_study(datastation_study, contributor, policy, investigation)
        study_attributes = datastation_study.seek_attributes.merge({ contributor: contributor,
                                                                     investigation: investigation, policy: policy.deep_copy })
        study = investigation.studies.build(study_attributes)
        populate_extended_metadata(study, datastation_study)
        record_activity(study, contributor, 'create')
        study
      end

      def build_investigation(datastation_inv, contributor, projects, policy)
        inv_attributes = datastation_inv.seek_attributes.merge({ contributor: contributor, projects: projects,
                                                                 policy: policy.deep_copy })
        investigation = ::Investigation.new(inv_attributes)
        populate_extended_metadata(investigation, datastation_inv)
        record_activity(investigation, contributor, 'create')
        investigation
      end

      def update_entity(seek_entity, datastation_entity, contributor)
        attributes = datastation_entity.seek_attributes
        seek_entity.assign_attributes(attributes)
        populate_extended_metadata(seek_entity, datastation_entity)
        record_update_activity_if_changed(seek_entity, contributor)
        seek_entity
      end

      def update_sample(seek_sample, datastation_sample, contributor)
        sample_attributes = datastation_sample.seek_attributes
        seek_sample.assign_attributes(sample_attributes)
        update_sample_metadata(seek_sample, datastation_sample)
        record_update_activity_if_changed(seek_sample, contributor)
        seek_sample
      end

      def update_or_build_study(datastation_study, contributor, projects, policy, investigation)
        study = ::Study.by_external_identifier(datastation_study.external_id, projects)
        if study
          update_entity(study, datastation_study, contributor)
          investigation.studies << study
        else
          study = build_study(datastation_study, contributor, policy, investigation)
        end
        study
      end

      def update_or_build_observation_unit(datastation_observation_unit, contributor, policy, study)
        observation_unit = ::ObservationUnit.by_external_identifier(datastation_observation_unit.external_id,
                                                                    study.projects)
        if observation_unit
          update_entity(observation_unit, datastation_observation_unit, contributor)
          observation_unit.study = study
          observation_unit.observation_unit_assets.delete_all
          datastation_observation_unit.datasets.each do |datastation_dataset|
            df = build_data_file(contributor, datastation_dataset, study.projects, policy)
            observation_unit.observation_unit_assets.build(asset: df)
          end
          observation_unit.samples = []
          study.observation_units << observation_unit
        else
          observation_unit = build_observation_unit(datastation_observation_unit, contributor, policy, study)
        end
        observation_unit
      end

      def update_or_build_sample(datastation_sample, contributor, projects, policy, observation_unit)
        sample = ::Sample.by_external_identifier(datastation_sample.external_id, projects)
        if sample
          update_sample(sample, datastation_sample, contributor)
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
          update_entity(assay, datastation_assay, contributor)
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
        if (emt = datastation_entity.find_closest_matching_extended_metadata_type)
          if emt != seek_entity.extended_metadata&.extended_metadata_type
            seek_entity.build_extended_metadata(extended_metadata_type: emt)
          end
          update_extended_metadata(seek_entity, datastation_entity)
        end
      end

      def update_extended_metadata(seek_entity, datastation_entity)
        datastation_entity.populate_extended_metadata(seek_entity)
      end

      def update_sample_metadata(seek_sample, datastation_sample)
        datastation_sample.populate_seek_sample(seek_sample)
      end

      def populate_sample(seek_sample, datastation_sample)
        if (sample_type = datastation_sample.find_closest_matching_sample_type(seek_sample.contributor))
          seek_sample.sample_type = sample_type
          update_sample_metadata(seek_sample, datastation_sample)
        else
          raise MissingSampleTypeException, 'Unable to find a matching Sample Type with suitable access rights'
        end
      end

      def build_data_file(contributor, datastation_dataset, projects, policy)
        @data_file_cache[datastation_dataset.external_id] ||= begin
          blob = ContentBlob.new(url: datastation_dataset.content_url.to_s,
                                 original_filename: datastation_dataset.identifier, external_link: true, is_webpage: true, content_type: 'application/octet-stream')
          data_file_attributes = datastation_dataset.seek_attributes.merge({
                                                                             contributor: contributor, projects: projects,
                                                                             content_blob: blob, policy: policy.deep_copy
                                                                           })
          data_file = DataFile.new(data_file_attributes)
          record_activity(data_file, contributor, 'create')
          data_file
        end
      end

      def record_activity(seek_entity, culprit, action)
        seek_entity.activity_logs.build(culprit: culprit, action: action, data: 'fair data station import')
      end

      def record_update_activity_if_changed(seek_entity, culprit)
        return unless seek_entity_changed?(seek_entity)

        record_activity(seek_entity, culprit, 'update')
      end

      def seek_entity_changed?(seek_entity)
        return true if seek_entity.changed?
        return true if seek_entity.respond_to?(:extended_metadata) && seek_entity.extended_metadata&.changed?

        false
      end
    end
  end
end
