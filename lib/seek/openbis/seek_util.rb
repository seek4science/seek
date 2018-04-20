module Seek
  module Openbis


    class SeekUtil


      FAKE_FILE_ASSAY_NAME = 'OpenBIS FILES'.freeze

      def createObisStudy(study_params, creator, obis_asset)

        experiment = obis_asset.content
        openbis_endpoint = obis_asset.seek_service

        study_params[:title] ||= extract_title(experiment) ## "OpenBIS #{experiment.perm_id}"
        study = Study.new(study_params)

        study.contributor = creator
        study.policy = openbis_endpoint.policy.deep_copy
        study.external_asset = obis_asset
        study
      end

      def createObisAssay(assay_params, creator, obis_asset)

        zample = obis_asset.content
        openbis_endpoint = obis_asset.seek_service

        assay_params[:assay_class_id] ||= AssayClass.for_type("experimental").id
        assay_params[:title] ||= extract_title(zample) ## "OpenBIS #{zample.perm_id}"
        assay = Assay.new(assay_params)

        assay.contributor = creator
        assay.policy = openbis_endpoint.policy.deep_copy
        assay.external_asset = obis_asset
        assay
      end

      def createDataFileFromObisSet(dataset, creator)
        obis_asset = OpenbisExternalAsset.find_or_create_by_entity(dataset)
        createObisDataFile({}, creator, obis_asset)
      end

      def createObisDataFile(datafile_params, creator, obis_asset)

        dataset = obis_asset.content
        # files are prefetched so the details are available even if OBis is down
        dataset.prefetch_files
        openbis_endpoint = obis_asset.seek_service

        datafile_params[:projects] = [openbis_endpoint.project]
        datafile_params[:title] ||= extract_title(dataset)
        datafile_params[:license] ||= openbis_endpoint.project.default_license
        df = DataFile.new(datafile_params)

        df.contributor = creator
        df.policy = openbis_endpoint.policy.deep_copy
        df.external_asset = obis_asset

        # datafile needs content blob as there is lots of seek code which assumes that content blob is present on assets
        df.content_blob = ContentBlob.create(url: uri_for_content_blob(obis_asset),
                                             make_local_copy: false,
                                             external_link: true, original_filename: "openbis-#{dataset.perm_id}")
        df
      end

      def extract_title(entity)

        title = "OpenBIS #{entity.code}"
        if entity.properties && entity.properties['NAME']
          title = entity.properties['NAME'] + ' ' + title
        end
        title
      end

      def uri_for_content_blob(obis_asset)
        openbis_endpoint = obis_asset.seek_service
        entity = obis_asset.content
        "openbis2:#{openbis_endpoint.id}/#{entity.class.name}/#{entity.perm_id}"
      end

      def legacy_uri_for_content_blob(dataset)
        openbis_endpoint = dataset.openbis_endpoint
        "openbis:#{openbis_endpoint.id}:dataset:#{dataset.perm_id}"
      end


      def fake_file_assay(study)

        assay = study.assays.where(title: FAKE_FILE_ASSAY_NAME).first
        return assay if assay

        assay_params = { assay_class_id: AssayClass.for_type("experimental").id,
                         title: FAKE_FILE_ASSAY_NAME,
                         description: 'Automatically generated assay to host openbis files that are linked to
the original OpenBIS experiment. Its content and linked data files will be updated by the system if automatic synchronization was selected.'
        }
        assay = Assay.new(assay_params)
        assay.contributor = study.contributor
        assay.policy = study.policy.deep_copy
        assay.study = study
        assay.save!
        assay
      end

      def sync_asset_content(obis_asset)

        begin
          entity = fetch_current_entity_version(obis_asset)
          entity.prefetch_files if entity.is_a? Seek::Openbis::Dataset
          obis_asset.content=entity
        rescue Exception => exception
          obis_asset.sync_state = :failed
          obis_asset.err_msg = sync_err_to_msg(exception, obis_asset)
        end

        # saving automatically triggers reindexing if needed
        obis_asset.save! unless obis_asset.new_record?

      end

      def sync_err_to_msg(exception, obis_asset)
        Rails.logger.error("Cannot sync #{obis_asset.external_type} #{obis_asset.external_id}")
        Rails.logger.error(exception)
        puts "#{exception.class}"
        puts "#{exception}"
        exception.to_s
      end

      def sync_external_asset(obis_asset)

        sync_asset_content(obis_asset)
        raise "Sync failed: #{obis_asset.err_msg}" if obis_asset.failed?

        errs = []
        errs = follow_dependent(obis_asset) if should_follow_dependent(obis_asset)
        raise errs.join(', ') unless errs.empty?

      end

      def should_follow_dependent(obis_asset)

        return false unless obis_asset.seek_entity
        return true if obis_asset.seek_entity.is_a? Assay
        return true if obis_asset.seek_entity.is_a? Study
        false
      end

      def fetch_current_entity_version(obis_asset)
        obis_asset.external_type.constantize.new(obis_asset.seek_service, obis_asset.external_id, true)
      end

      def follow_dependent(obis_asset)

        return follow_study_dependent(obis_asset.seek_entity) if obis_asset.seek_entity.is_a? Study
        return follow_assay_dependent(obis_asset.seek_entity) if obis_asset.seek_entity.is_a? Assay
        raise "Not supported openbis following of #{obis_asset.seek_entity.class} from #{obis_asset}"

      end

      def follow_study_dependent(study)

        asset = study.external_asset
        entity = asset.content
        sync_options = asset.sync_options

        issues = []

        issues.concat follow_study_dependent_assays(entity, study, sync_options)

        issues.concat follow_study_dependent_datafiles(entity, study, sync_options)
        issues
      end

      def follow_study_dependent_assays(entity, study, sync_options)

        zamples = extract_requested_assays(entity, sync_options)

        assay_sync = simplify_assay_sync(sync_options)
        associate_zamples_as_assays(study, zamples, assay_sync)

      end

      def simplify_assay_sync(sync_options)
        sync_options = sync_options.clone
        sync_options.delete(:linked_assays)
        sync_options
      end

      def associate_zample_ids_as_assays(study, zamples_ids, sync_options, endpoint)
        return [] if zamples_ids.empty?


        zamples = Seek::Openbis::Zample.new(endpoint).find_by_perm_ids(zamples_ids)
        associate_zamples_as_assays(study, zamples, sync_options)
      end

      def associate_zamples_as_assays(study, zamples, sync_options)

        return [] if zamples.empty?
        issues = []

        external_assets = zamples.map { |ds| OpenbisExternalAsset.find_or_create_by_entity(ds) }

        # warn about non assay
        non_assays = external_assets.reject { |es| es.seek_entity.nil? || es.seek_entity.is_a?(Assay) }
        issues.concat non_assays.map { |es| "#{es.external_id} already registered as #{es.seek_entity.class} #{es.seek_entity.id}" }

        existing_assays = external_assets.select { |es| es.seek_entity.is_a? Assay }
                              .map { |es| es.seek_entity }

        # warn about already linked somewhere else
        issues.concat existing_assays.reject { |es| es.study.id == study.id }
                          .map { |es| "#{es.external_asset.external_id} already registered under different Study #{es.study.id}" }

        # only own assays
        existing_assays = existing_assays.select { |es| es.study.id == study.id }

        # params must be cloned so they will be independent in each creation
        assay_params = { study_id: study.id }
        contributor = study.contributor

        new_assays = external_assets.select { |es| es.seek_entity.nil? }
                         .map do |es|
          es.sync_options = sync_options.clone
          createObisAssay(assay_params.clone, contributor, es)
        end

        saved = []

        new_assays.each do |df|
          if df.save
            saved << df
          else
            issues.concat df.errors.full_messages()
          end
        end

        assays = existing_assays+saved

        assays.each { |a| issues.concat follow_assay_dependent(a) }

        issues
      end

      def follow_assay_dependent(assay)

        asset = assay.external_asset
        entity = asset.content
        sync_options = asset.sync_options

        issues = []
        issues.concat follow_assay_dependent_datafiles(entity, assay, sync_options)
        issues
      end

      def follow_assay_dependent_datafiles(entity, assay, sync_options)

        data_sets_ids = extract_requested_sets(entity, sync_options)
        associate_data_sets_ids(assay, data_sets_ids, entity.openbis_endpoint)

      end

      def follow_study_dependent_datafiles(entity, study, sync_options)

        data_sets_ids = extract_requested_sets(entity, sync_options)
        return [] if data_sets_ids.empty?

        assay = fake_file_assay(study)
        associate_data_sets_ids(assay, data_sets_ids, entity.openbis_endpoint)
      end

      def associate_data_sets_ids(assay, data_sets_ids, endpoint)
        return [] if data_sets_ids.empty?

        data_sets = Seek::Openbis::Dataset.new(endpoint).find_by_perm_ids(data_sets_ids)
        associate_data_sets(assay, data_sets)
      end

      def associate_data_sets(assay, data_sets)

        return [] if data_sets.empty?
        issues = []

        external_assets = data_sets.map { |ds| OpenbisExternalAsset.find_or_create_by_entity(ds) }

        # warn about non datafiles
        non_files = external_assets.reject { |es| es.seek_entity.nil? || es.seek_entity.is_a?(DataFile) }
        issues.concat non_files.map { |es| "#{es.external_id} already registered as #{es.seek_entity.class} #{es.seek_entity.id}" }

        existing_files = external_assets.select { |es| es.seek_entity.is_a? DataFile }
                             .map { |es| es.seek_entity }

        # they have to be cloned before each creation!
        datafile_params = {}
        contributor = assay.contributor
        new_files = external_assets.select { |es| es.seek_entity.nil? }
                        .map { |es| createObisDataFile(datafile_params.clone, contributor, es) }

        saved = []

        new_files.each do |df|
          if df.save
            saved << df
          else
            issues.concat df.errors.full_messages()
          end
        end

        data_files = existing_files+saved
        data_files.each { |df| assay.associate(df) }

        issues
      end


      def extract_requested_sets(entity, sync_options)
        return entity.dataset_ids if sync_options[:link_datasets] == '1'
        (sync_options[:linked_datasets] || []) & entity.dataset_ids
      end

      def extract_requested_assays(entity, sync_options)

        sample_ids = (sync_options[:link_assays] == '1') ? entity.sample_ids : (sync_options[:linked_assays] || []) & entity.sample_ids
        zamples = Seek::Openbis::Zample.new(entity.openbis_endpoint).find_by_perm_ids(sample_ids)

        zamples = filter_assay_like_zamples(zamples, entity.openbis_endpoint) if (sync_options[:link_assays] == '1')
        zamples
      end

      def filter_assay_like_zamples(zamples, openbis_endpoint)
        types = assay_types(openbis_endpoint).map(&:code)

        zamples
            .select { |s| types.include? s.type_code }
      end

      def assay_types(openbis_endpoint, use_semantic = false)


        types = []
        if use_semantic
          semantic = Seek::Openbis::SemanticAnnotation.new

          semantic.predicateAccessionId = 'is_a'
          semantic.descriptorAccessionId = 'assay'

          types.concat Seek::Openbis::EntityType.SampleType(openbis_endpoint).find_by_semantic(semantic)
        end

        assay_codes = openbis_endpoint.assay_types
        types.concat(Seek::Openbis::EntityType.SampleType(openbis_endpoint).find_by_codes(assay_codes)) unless assay_codes.empty?

        types
      end

      def dataset_types(openbis_endpoint)
        Seek::Openbis::EntityType.DataSetType(openbis_endpoint).all
      end

      def study_types(openbis_endpoint)

        study_codes = openbis_endpoint.study_types
        return [] if study_codes.empty?

        Seek::Openbis::EntityType.ExperimentType(openbis_endpoint).find_by_codes(study_codes)

      end
    end
  end
end
