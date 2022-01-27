module Seek
  module Openbis
    # An ugly util class that contains most of the OpenBIS to SEEK logic.
    # could not think how to spread the code better, as Experiments registration may involve Sample registration
    # and data files registration ... so all is in one bag. The controllers have very similar behaviour but still
    # they are not exactly same.
    # On bright side, this logic can be tested without using the whole rails app internals
    class SeekUtil
      DEBUG = Seek::Config.openbis_debug ? true : false

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

        assay_params[:assay_class_id] ||= AssayClass.for_type('experimental').id
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

        df.contributor = creator.try(:person)
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

      # that can be used for migration from first release of OBIS integration
      def legacy_uri_for_content_blob(dataset)
        openbis_endpoint = dataset.openbis_endpoint
        "openbis:#{openbis_endpoint.id}:dataset:#{dataset.perm_id}"
      end

      def fake_file_assay(study)
        assay = study.assays.where(title: FAKE_FILE_ASSAY_NAME).first
        return assay if assay

        assay_params = {assay_class_id: AssayClass.for_type('experimental').id,
                        title: FAKE_FILE_ASSAY_NAME,
                        description: 'Automatically generated assay to host openbis files that are linked to
the original OpenBIS experiment. Its content and linked data files will be updated by the system
if automatic synchronization was selected.'}
        assay = Assay.new(assay_params)
        assay.contributor = valid_current_person # study.contributor
        assay.policy = study.policy.deep_copy
        assay.study = study

        try_to_save(assay)
      end

      def try_to_save(entity)
        unless entity.save
          raise "Could not save #{entity.class}, reported issues #{entity.errors.full_messages}"
        end
        entity
      end

      def sync_asset_content(obis_asset)
        begin
          entity = fetch_current_entity_version(obis_asset)
          entity.prefetch_files if entity.is_a? Seek::Openbis::Dataset
          obis_asset.content = entity
        rescue => exception
          obis_asset.add_failure handle_sync_err(exception, obis_asset)
        end

        # saving automatically triggers reindexing if needed
        try_to_save(obis_asset) unless obis_asset.new_record?
      end

      def handle_sync_err(exception, obis_asset)
        Rails.logger.error("Cannot sync #{obis_asset.external_type} #{obis_asset.external_id}")
        log_error(exception)

        extract_err_message(exception)
      end

      def extract_err_message(exception)
        if exception.is_a? Fairdom::OpenbisApi::OpenbisQueryException
          return 'Cannot connect to the OpenBIS server' if exception.message && exception.message.include?('java.net.ConnectException')
          return 'Cannot access OpenBIS: Invalid username or password' if exception.message && exception.message.include?('Invalid username or password')
        end

        exception.class.to_s
      end

      def sync_external_asset(obis_asset)

        errs = []
        begin
          sync_asset_content(obis_asset)

          return ["Sync failed: #{obis_asset.err_msg}"] if obis_asset.failed?

          errs = follow_dependent_from_asset(obis_asset).issues if should_follow_dependent(obis_asset)

        rescue => exception
          msg = log_error(exception, 'Sync FATAL ERROR')
          errs << msg
        end

        unless errs.empty?
          msg = errs.join(',\n');
          msg = msg.slice(0, 250) if msg.length > 250
          obis_asset.err_msg = msg
          try_to_save(obis_asset)
        end

        errs
      end

      def should_follow_dependent(obis_asset)
        return false unless Seek::Config.openbis_check_new_arrivals
        return false unless obis_asset.sync_options[:new_arrivals]
        return false unless obis_asset.seek_entity
        return true if obis_asset.seek_entity.is_a? Assay
        return true if obis_asset.seek_entity.is_a? Study
        false
      end

      def fetch_current_entity_version(obis_asset)
        obis_asset.external_type.constantize.new(obis_asset.seek_service, obis_asset.external_id, true)
      end

      def follow_dependent_from_asset(obis_asset)
        follow_dependent_from_seek(obis_asset.seek_entity)
      end

      def follow_dependent_from_seek(seek_entity)
        return follow_study_dependent(seek_entity) if seek_entity.is_a? Study
        return follow_assay_dependent(seek_entity) if seek_entity.is_a? Assay
        return Seek::Openbis::RegistrationInfo.new if seek_entity.is_a? DataFile
        raise "Not supported openbis following of #{seek_entity.class}"
      end

      def follow_study_dependent(study)
        reg_info = Seek::Openbis::RegistrationInfo.new

        asset = study.external_asset
        entity = asset.content
        sync_options = asset.sync_options

        reg_info.merge follow_study_dependent_assays(entity, study, sync_options)

        reg_info.merge follow_study_dependent_datafiles(entity, study, sync_options)

        reg_info
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
        return Seek::Openbis::RegistrationInfo.new if zamples_ids.empty?

        zamples = Seek::Openbis::Zample.new(endpoint).find_by_perm_ids(zamples_ids)
        associate_zamples_as_assays(study, zamples, sync_options)
      end

      def valid_current_person

        user = User.current_user
        raise 'Cannot add new entities with nil current_user' if user.nil?

        person = case user
                 when User
                   user.person
                 when Person
                   p = user
                   user = p.user
                   p
                 else
                   raise "Cannot add new entities unsupported current_user type #{user.class}"
                 end

        raise 'Cannot add new entities with guest current_user' if user.guest?
        person
      end

      def associate_zamples_as_assays(study, zamples, sync_options)
        reg_info = Seek::Openbis::RegistrationInfo.new
        return reg_info if zamples.empty?

        external_assets = zamples.map {|ds| OpenbisExternalAsset.find_or_create_by_entity(ds)}

        # warn about non assay
        reg_info.add_issues validate_expected_seek_type(external_assets, Assay)

        existing_assays = external_assets.select {|es| es.seek_entity.is_a? Assay}
                              .map(&:seek_entity)

        # warn about already linked somewhere else
        reg_info.add_issues validate_study_relationship(existing_assays, study)

        # only own assays
        existing_assays = existing_assays.select {|es| es.study.id == study.id}

        # params must be cloned so they will be independent in each creation
        assay_params = {study_id: study.id}
        contributor = valid_current_person # study.contributor


        # new_assays
        external_assets
            .select {|es| es.seek_entity.nil?}
            .map do |es|
          es.sync_options = sync_options.clone
          createObisAssay(assay_params.clone, contributor, es)
        end
            .each do |df|
          if df.save
            reg_info.add_created df
          else
            reg_info.add_issues df.errors.full_messages
          end
        end

        assays = existing_assays + reg_info.created

        assays.each {|a| reg_info.merge follow_assay_dependent(a)}

        reg_info
      end

      def follow_assay_dependent(assay)
        asset = assay.external_asset
        entity = asset.content
        sync_options = asset.sync_options

        follow_assay_dependent_datafiles(entity, assay, sync_options)
      end

      def follow_assay_dependent_datafiles(entity, assay, sync_options)
        data_sets_ids = extract_requested_sets(entity, sync_options)
        associate_data_sets_ids(assay, data_sets_ids, entity.openbis_endpoint)
      end

      def follow_study_dependent_datafiles(entity, study, sync_options)
        reg_info = Seek::Openbis::RegistrationInfo.new

        data_sets_ids = extract_requested_sets(entity, sync_options)
        return reg_info if data_sets_ids.empty?

        begin
          assay = fake_file_assay(study)
        rescue => exception # probably permission issue
          msg = extract_err_message(exception)
          log_error(exception)
          reg_info.add_issues msg
          return reg_info
        end

        reg_info.add_created assay

        reg_info.merge associate_data_sets_ids(assay, data_sets_ids, entity.openbis_endpoint)
        reg_info
      end

      def log_error(exception, at = '')
        msg = "#{at} #{exception.class} #{exception.message}\n #{exception.backtrace.join('\n\t')}"
        Rails.logger.error msg
        msg
      end

      def associate_data_sets_ids(assay, data_sets_ids, endpoint)
        return Seek::Openbis::RegistrationInfo.new if data_sets_ids.empty?

        data_sets = Seek::Openbis::Dataset.new(endpoint).find_by_perm_ids(data_sets_ids)
        associate_data_sets(assay, data_sets)
      end

      def associate_data_sets(assay, data_sets)
        reg_info = Seek::Openbis::RegistrationInfo.new
        return reg_info if data_sets.empty?

        external_assets = data_sets.map {|ds| OpenbisExternalAsset.find_or_create_by_entity(ds)}

        # warn about non datafiles
        reg_info.add_issues validate_expected_seek_type(external_assets, DataFile)

        existing_files = external_assets.select {|es| es.seek_entity.is_a? DataFile}
                             .map(&:seek_entity)

        # params have to be cloned before each creation!
        datafile_params = {}
        contributor = valid_current_person # assay.contributor
        new_files = external_assets
                        .select {|es| es.seek_entity.nil?}
                        .map {|es| createObisDataFile(datafile_params.clone, contributor, es)}


        new_files.each do |df|
          if df.save
            reg_info.add_created df
          else
            reg_info.add_issues df.errors.full_messages
          end
        end

        # associate with the assay
        (existing_files | reg_info.created).each do |df|
          assay.associate(df)
        end

        reg_info
      end

      def validate_expected_seek_type(collection, type)
        # warn about wrong type
        collection.reject {|es| es.seek_entity.nil? || es.seek_entity.is_a?(type)}
            .map {|es| "#{es.external_id} already registered as #{es.seek_entity.class} #{es.seek_entity.id}"}
      end

      def validate_study_relationship(collection, study)
        # warn about already linked somewhere else
        collection
            .reject {|es| es.study.id == study.id}
            .map {|es| "#{es.external_asset.external_id} already registered under different Study #{es.study.id}"}
      end

      def extract_requested_sets(entity, sync_options)
        return entity.dataset_ids if sync_options[:link_datasets] == '1'
        (sync_options[:linked_datasets] || []) & entity.dataset_ids
      end

      def extract_requested_assays(entity, sync_options)

        sample_ids = if sync_options[:link_assays] == '1'
                       entity.sample_ids
                     else
                       (sync_options[:linked_assays] || []) & entity.sample_ids
                     end

        candidates = Seek::Openbis::Zample.new(entity.openbis_endpoint)
                         .find_by_perm_ids(sample_ids)

        zamples = []
        zamples.concat(filter_assay_like_zamples(candidates, entity.openbis_endpoint)) if sync_options[:link_assays] == '1'
        zamples.concat(candidates.select {|s| sync_options[:linked_assays].include? s.perm_id}) if sync_options[:linked_assays]

        zamples.uniq
      end

      def filter_assay_like_zamples(zamples, openbis_endpoint)
        # could have use the types codes directly but in theory
        # it can use semantic anotiations so there must be a query to OpenBIS
        # hance the types will be returned not just string
        types = assay_types(openbis_endpoint).map(&:code)

        zamples.select {|s| types.include? s.type_code}
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
        unless assay_codes.empty?
          types.concat(Seek::Openbis::EntityType.SampleType(openbis_endpoint).find_by_codes(assay_codes))
        end
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
