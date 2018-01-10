module Seek
  module Openbis

    class SeekUtil

      def createObisStudy(study_params, creator, obis_asset)

        experiment = obis_asset.content

        study_params[:title] ||= "OpenBIS #{experiment.perm_id}"
        study = Study.new(study_params)
        study.contributor = creator

        study.external_asset = obis_asset
        study
      end

      def createObisAssay(assay_params, creator, obis_asset)

        zample = obis_asset.content
        assay_params[:assay_class_id] ||= AssayClass.for_type("experimental").id
        assay_params[:title] ||= "OpenBIS #{zample.perm_id}"
        assay = Assay.new(assay_params)
        assay.contributor = creator

        assay.external_asset = obis_asset
        assay
      end

      def createObisDataFile(obis_asset)

        dataset = obis_asset.content
        openbis_endpoint = obis_asset.seek_service

        df = DataFile.new(projects: [openbis_endpoint.project], title: "OpenBIS #{dataset.perm_id}",
                          license: openbis_endpoint.project.default_license)

        df.policy=openbis_endpoint.policy.deep_copy
        df.external_asset = obis_asset
        df
      end

      def sync_external_asset(obis_asset)

        entity = fetch_current_entity_version(obis_asset)

        errs = follow_dependent(obis_asset,entity) if should_follow_dependent(obis_asset)
        raise errs if errs

        obis_asset.content=entity
        obis_asset.save!
      end

      def should_follow_dependent(obis_asset)

        return false unless obis_asset.seek_entity.is_a? Assay
        obis_asset.sync_options[:link_datasets] == '1'
      end

      def fetch_current_entity_version(obis_asset)
        obis_asset.external_type.constantize.new(obis_asset.seek_service, obis_asset.external_id,true)
      end

      def follow_dependent(obis_asset, current_entity)

        puts 'following dependent'
        data_sets_ids = current_entity.dataset_ids || []
        associate_data_sets_ids(obis_asset.seek_entity, data_sets_ids, obis_asset.seek_service)

      end

      def associate_data_sets_ids(assay, data_sets_ids, endpoint)
        return nil if data_sets_ids.empty?

        data_sets = Seek::Openbis::Dataset.new(endpoint).find_by_perm_ids(data_sets_ids)
        associate_data_sets(assay, data_sets)
      end

      def associate_data_sets(assay, data_sets)

        external_assets = data_sets.map { |ds| OpenbisExternalAsset.find_or_create_by_entity(ds) }

        existing_files = external_assets.select { |es| es.seek_entity.is_a? DataFile }
                             .map { |es| es.seek_entity }

        new_files = external_assets.select { |es| es.seek_entity.nil? }
                        .map { |es| createObisDataFile(es) }

        issues = []
        saved =  []

        new_files.each do |df|
          if df.save
            saved << df
          else
            issues.concat df.errors.full_messages()
          end
        end

        data_files = existing_files+saved
        data_files.each { |df| assay.associate(df) }

        issues.empty? ? nil : issues
      end

      def associate_zample_ids_as_assays(study, zamples_ids, sync_options, endpoint)
        return [] if zamples_ids.empty?

        zamples = Seek::Openbis::Zample.new(endpoint).find_by_perm_ids(zamples_ids)
        associate_zamples_as_assays(study, zamples, sync_options)
      end

      def associate_zamples_as_assays(study, zamples, sync_options)

        issues = []

        external_assets = zamples.map { |ds| OpenbisExternalAsset.find_or_create_by_entity(ds) }

        non_assays = external_assets.reject { |es| es.seek_entity.nil? || es.seek_entity.is_a?(Assay) }
        non_assays.each {|ea| puts "#{ea.external_id} #{ea.seek_entity}"}

        issues.concat non_assays.map { |es| "#{es.external_id} already registered as #{es.seek_entity.class} #{es.seek_entity.id}"}

        existing_assays = external_assets.select { |es| es.seek_entity.is_a? Assay }
                              .map { |es| es.seek_entity }

        issues.concat existing_assays.reject { |es| es.study.id == study.id }
                            .map { |es| "#{es.external_asset.external_id} already registered under different Study #{es.study.id}" }

        existing_assays = existing_assays.select { |es| es.study.id == study.id }

        assay_params = {study_id: study.id}
        contributor = study.contributor

        new_assay = external_assets.select { |es| es.seek_entity.nil? }
                        .map do |es|
                          es.sync_options = sync_options
                          createObisAssay(assay_params, contributor, es)
                        end

        saved = []

        new_assay.each do |df|
          if df.save
            saved << df
          else
            issues.concat df.errors.full_messages()
          end
        end

        assays = existing_assays+saved
        #follow_dependent on assay assays.each { |df| assay.associate(df) }

        issues
      end

      def assay_types(openbis_endpoint)

        semantic = Seek::Openbis::SemanticAnnotation.new

        semantic.predicateAccessionId = 'is_a'
        semantic.descriptorAccessionId = 'assay'

        Seek::Openbis::EntityType.SampleType(openbis_endpoint).find_by_semantic(semantic)

      end

      def dataset_types(openbis_endpoint)
        Seek::Openbis::EntityType.DataSetType(openbis_endpoint).all
      end

      def study_types(openbis_endpoint)

        study_codes = ['DEFAULT_EXPERIMENT']

        Seek::Openbis::EntityType.ExperimentType(openbis_endpoint).find_by_codes(study_codes)

      end
    end
  end
end
