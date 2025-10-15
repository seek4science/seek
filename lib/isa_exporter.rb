# noinspection ALL
module ISAExporter
  class Exporter
    def initialize(investigation, user)
      @investigation = investigation
      @current_user = user
      @OBJECT_MAP = {}
    end

    def convert_investigation
      raise "Only ISA-JSON compliant investigations can be exported to an ISA-JSON" unless @investigation.is_isa_json_compliant?
      isa_investigation = {}
      isa_investigation[:identifier] = '' # @investigation.id
      isa_investigation[:title] = @investigation.title
      isa_investigation[:description] = @investigation.description || ''
      isa_investigation[:submissionDate] = '' # @investigation.created_at.to_date.iso8601
      isa_investigation[:publicReleaseDate] = '' # @investigation.created_at.to_date.iso8601
      isa_investigation[:ontologySourceReferences] = convert_ontologies
      isa_investigation[:filename] = "#{@investigation.title}.txt"
      isa_investigation[:comments] = [
        { name: 'ISAjson export time', value: Time.now.utc.iso8601 },
        { name: 'SEEK Project name', value: @investigation.projects.first.title },
        {
          name: 'SEEK Project ID',
          value:
            File.join(Seek::Config.site_base_host, Seek::Util.routes.single_page_path(@investigation.projects.first))
        },
        { name: 'SEEK Investigation ID', value: @investigation.id.to_s }
      ]

      publications = []
      @investigation.publications.each { |p| publications << convert_publication(p) }
      isa_investigation[:publications] = publications

      people = []
      @investigation.related_people.each { |p| people << convert_person(p) }
      isa_investigation[:people] = people

      studies = []

      unless @investigation.studies.all?(&:is_isa_json_compliant?)
          raise "All studies in investigation '#{investigation.title}' should be ISA-JSON compliant"
      end

      @investigation.studies.each { |s| studies << convert_study(s) if s.can_view?(@current_user) }
      isa_investigation[:studies] = studies

      @OBJECT_MAP = @OBJECT_MAP.merge(isa_investigation)

      isa_investigation
    end

    def convert_study_comments(study)
      study_comments = []
      study_id = study.id

      # Study Custom Metadata
      unless study.extended_metadata.nil?
        json = JSON.parse(study.extended_metadata.json_metadata)
        extended_metadata_attributes = study.extended_metadata.extended_metadata_attributes
        em_id = study.extended_metadata.id
        json.map do |key, val|
          ema_id = extended_metadata_attributes.detect { |ema| ema.title == key }&.id
          study_comments.push({
            '@id': "#study_comment/#{ [study_id, em_id, ema_id].join('_') }",
            'name': key,
            'value': val
          })
        end
      end

      study_comments.append({
        '@id': "#study_comment/#{ [study_id, UUID.new.generate].join('_') }",
        'name': 'SEEK Study ID',
        'value': study_id.to_s
      })
      study_comments.append({
        '@id': "#study_comment/#{ [study_id, UUID.new.generate].join('_') }",
        'name': 'SEEK creation date',
        'value': study.created_at.utc.iso8601
      })
    end

    def convert_study(study)
      isa_study = {}
      isa_study[:identifier] = '' # study.id
      isa_study[:title] = study.title
      isa_study[:description] = study.description || ''
      isa_study[:submissionDate] = '' # study.created_at.to_date.iso8601
      isa_study[:publicReleaseDate] = '' # study.created_at.to_date.iso8601
      isa_study[:filename] = "#{study.title}.txt"
      isa_study[:comments] = convert_study_comments(study)

      publications = []
      study.publications.each { |p| publications << convert_publication(p) }
      study.assays.each do |assay|
        assay.publications.each { |p| publications << convert_publication(p) }
      end
      isa_study[:publications] = publications

      people = []
      study.related_people.each { |p| people << convert_person(p) }
      isa_study[:people] = people
      isa_study[:studyDesignDescriptors] = []
      isa_study[:characteristicCategories] = convert_characteristic_categories(study)
      protocols_maps = fetch_study_protocols(study)
      isa_study[:protocols] = protocols_maps.map { |p| p[:protocols] }.compact.flatten
      isa_study[:materials] = {
        sources: convert_materials_sources(study.sample_types.first),
        samples: convert_materials_samples(study.sample_types.second)
      }


      study_protocols_map = protocols_maps.detect { |pm| pm[:sample_type_id] == study.sample_types.second.id }
      isa_study[:processSequence] = convert_process_sequence(study.sample_types.second, study_protocols_map)

      unless study.assays.all?(&:is_isa_json_compliant?)
        raise "All assays in study `#{study.title}` should be ISA-JSON compliant."
      end

      isa_study[:assays] = study.assay_streams.map { |assay_stream| convert_assays(assay_stream, protocols_maps) }.compact
      isa_study[:factors] = []
      isa_study[:unitCategories] = []

      isa_study
    end

    def fetch_study_protocols(study)
      protocols_maps = []

      # Get all sample types from study and its assays
      sample_type_objcts = [{ sample_type: study.sample_types.second, isa: 'study', isa_id: study.id }]
      sample_type_objcts += study.assay_streams.map(&:child_assays).flatten.map(&:sample_type).map do |sample_type|
        { sample_type: sample_type, isa: 'assay', isa_id: sample_type.assays.first.id }
      end

      sample_type_objcts.each do |sample_type_object|
        sample_type, isa, isa_id = sample_type_object[:sample_type], sample_type_object[:isa], sample_type_object[:isa_id]
        protocol_attribute = sample_type.sample_attributes.detect { |sa| sa.isa_tag&.isa_protocol? }
        parameter_attributes = sample_type.sample_attributes.select { |sa| sa.isa_tag&.isa_parameter_value? }.compact
        next if protocol_attribute.blank?

        is_registered_sop = protocol_attribute.sample_attribute_type.seek_sop?
        # Get used SOPs
        if is_registered_sop
          used_sops = sample_type.samples.map do |sample|
            sop = sample.get_attribute_value(protocol_attribute)
            raise "Sample {#{sample.id}: #{sample.title}} has no registered SOP as protocol" if sop.blank?
            Sop.find_by_id(sop['id'])
          end.uniq
        else
          used_sops = sample_type.samples.map do |sample|
            protocol_title = sample.get_attribute_value(protocol_attribute)
            raise "Sample {#{sample.id}: #{sample.title}} has no protocol" if protocol_title.blank?
            { id: protocol_attribute.id, title: protocol_title, description: '' }
          end.uniq
        end

        # generate & append to protcols
        protocols_maps.append({ protocols: used_sops.map do |sop|
          id = "#protocol/#{isa}_#{isa_id}_#{sop[:id]}"
          convert_protocol(sop, id, protocol_attribute, parameter_attributes)
        end, isa: isa, isa_id: isa_id, sample_type_id: sample_type.id })
      end

      protocols_maps
    end

    def convert_annotation(term_uri)
      isa_annotation = {}
      term = term_uri.split('#')[1]
      isa_annotation[:annotationValue] = term
      isa_annotation[:termAccession] = term_uri
      isa_annotation[:termSource] = 'jerm_ontology'
      isa_annotation
    end

    def convert_assay_comments(assay_stream)
      assay_comments = []
      assay_stream_id = assay_stream&.id

      linked_assays = assay_stream.child_assays.map { |assay| { 'id': assay.id, 'title': assay.title } }.to_json

      study_id = assay_stream.study_id
      return [] if assay_stream.extended_metadata.nil?

      json = JSON.parse(assay_stream.extended_metadata&.json_metadata)
      cm_attributes = assay_stream.extended_metadata.extended_metadata_attributes
      cm_id = assay_stream.extended_metadata&.id
      json.map do |key, val|
        cma_id = cm_attributes.detect { |cma| cma.title == key }&.id
        assay_comments.push({
          '@id': "#assay_comment/#{[study_id, assay_stream_id, cm_id, cma_id].join('_')}",
          'name': key,
          'value': val
        })
      end

      assay_comments.push({
        '@id': "#assay_comment/#{assay_stream_id}",
        'name': 'linked_assays',
        'value': linked_assays
      })
      assay_comments.compact
    end

    def convert_assays(assay_stream, protocols_maps)
      child_assays = assay_stream.child_assays
      return unless assay_stream.can_view?(@current_user)
      return unless child_assays.all? { |a| a.can_view?(@current_user) }

      child_assays.map do |ca|
        unless ca.sample_type.present?
          raise "No Sample type was found in Assay '#{ca.id} - #{ca.title}'," \
                " part of Assay Stream '#{assay_stream.id - assay_stream.title}'"
        end
      end

      all_sample_types = child_assays.map(&:sample_type).compact

      # stream_name = "assays_#{child_assays.pluck(:id).join('_')}"
      stream_name = "#{ assay_stream.title }_#{assay_stream.id}_#{child_assays.pluck(:id).join('_')}"
      assay_comments = convert_assay_comments(assay_stream)

      # Retrieve assay_stream if
      # stream_name_comment = assay_comments.detect { |ac| ac[:name] == 'assay_stream' }
      # stream_name = stream_name_comment[:value] unless stream_name_comment.nil?

      isa_assay = {}
      isa_assay['@id'] = "#assay/#{child_assays.pluck(:id).join('_')}"
      isa_assay[:filename] = "a_#{stream_name.downcase.tr(" ", "_")}.txt"
      isa_assay[:measurementType] = { annotationValue: '', termSource: '', termAccession: '' }
      isa_assay[:technologyType] = { annotationValue: '', termSource: '', termAccession: '' }
      isa_assay[:comments] = assay_comments
      isa_assay[:technologyPlatform] = ''
      isa_assay[:characteristicCategories] = convert_characteristic_categories(nil, child_assays)
      isa_assay[:materials] = {
        # Here, the first assay's samples will be enough
        samples: assay_samples(child_assays.first), # the samples from study level that are referenced in this assay's samples,
        otherMaterials: convert_other_materials(all_sample_types)
      }
      isa_assay[:processSequence] =
        child_assays.map do |assay|
          assay_protocols_map = protocols_maps.detect { |pm| pm[:sample_type_id] == assay.sample_type.id }
          convert_process_sequence(assay.sample_type,assay_protocols_map)
        end.flatten
      isa_assay[:dataFiles] = convert_data_files(all_sample_types)
      isa_assay[:unitCategories] = []
      isa_assay
    end

    def convert_person(person)
      isa_person = { '@id': "#people/#{person.id}" }
      isa_person[:lastName] = person.last_name
      isa_person[:firstName] = person.first_name
      isa_person[:midInitials] = ''
      isa_person[:email] = person.email
      isa_person[:phone] = person.phone || ''
      isa_person[:fax] = ''
      isa_person[:address] = ''
      isa_person[:affiliation] = ''
      roles = {}
      roles[:termAccession] = ''
      roles[:termSource] = ''
      roles[:annotationValue] = ''
      isa_person[:roles] = [roles]
      isa_person[:comments] = [{ '@id': '', value: '', name: '' }]
      isa_person
    end

    def convert_publication(publication)
      isa_publication = {}
      isa_publication[:pubMedID] = publication.pubmed_id
      isa_publication[:doi] = publication.doi
      status = {}
      status[:termAccession] = ''
      status[:termSource] = ''
      status[:annotationValue] = ''
      isa_publication[:status] = status
      isa_publication[:title] = publication.title
      isa_publication[:author_list] = publication.seek_authors.map(&:full_name).join(', ')

      isa_publication[:comments] = [
        {
          "@id": "#publication_comment/#{publication.id}_#{publication.assays.map(&:id).join('_')}",
          "name": "linked_assays",
          "value": publication.assays.map { |assay| {"id": assay.id, "title": assay.title} }.to_json
        },
        {
          "@id": "#publication_comment/#{publication.id}_#{publication.studies.map(&:id).join('_')}",
          "name": "linked_studies",
          "value": publication.studies.map { |study| {"id": study.id, "title": study.title} }.to_json
        }
      ]

      isa_publication
    end

    def convert_ontologies
      source_ontologies = []
      sample_types = @investigation.studies.map(&:sample_types) + @investigation.assays
                                                                                .select(&:is_assay_stream?)
                                                                                .map(&:child_assays)
                                                                                .compact
                                                                                .flatten
                                                                                .map(&:sample_type)
                                                                                .compact

      sample_types.flatten.each do |sa|
        sa.sample_attributes.each do |atr|
          source_ontologies << atr.sample_controlled_vocab.source_ontology if atr.ontology_based?
        end
      end
      source_ontologies.uniq.map { |s| { name: s, file: '', version: '', description: '' } }
    end

    def convert_protocol(sop, id, protocol_attrbute, parameter_attributes)
      isa_protocol = {}

      isa_protocol['@id'] = id
      isa_protocol[:name] = sop[:title]

      ontology = get_ontology_details(protocol_attrbute, protocol_attrbute.title, false)

      isa_protocol[:protocolType] = {
        annotationValue: protocol_attrbute.title,
        termAccession: ontology[:termAccession],
        termSource: ontology[:termSource]
      }
      isa_protocol[:description] = sop[:description] || ''
      isa_protocol[:uri] = ontology[:termAccession]
      isa_protocol[:version] = ''
      isa_protocol[:parameters] =
        parameter_attributes.map do |parameter|
          parameter_value_ontology =
            if parameter.pid.present?
              get_ontology_details(parameter, parameter.title, false)
            else
              { termAccession: '', termSource: '' }
            end
          {
            '@id': "#parameter/#{parameter.id}",
            parameterName: {
              annotationValue: parameter.title,
              termAccession: parameter_value_ontology[:termAccession],
              termSource: parameter_value_ontology[:termSource]
            }
          }
        end
      isa_protocol[:components] = [
        { componentName: '', componentType: { annotationValue: '', termSource: '', termAccession: '' } }
      ]

      isa_protocol
    end

    def convert_materials_sources(sample_type)
      with_tag_source = sample_type.sample_attributes.detect { |sa| sa.isa_tag&.isa_source? }
      with_tag_source_characteristic =
        sample_type.sample_attributes.select { |sa| sa.isa_tag&.isa_source_characteristic? }

      sample_type.samples.map do |s|
        if s.can_view?(@current_user)
          {
            '@id': "#source/#{s.id}",
            name: s.get_attribute_value(with_tag_source),
            characteristics: convert_characteristics(s, with_tag_source_characteristic)
          }
        else
          {
            '@id': "#source/HIDDEN",
            name: 'Hidden Sample',
            characteristics: []
          }
        end
      end
    end

    def convert_materials_samples(sample_type)
      with_tag_sample = sample_type.sample_attributes.detect { |sa| sa.isa_tag&.isa_sample? }
      with_tag_sample_characteristic =
        sample_type.sample_attributes.select { |sa| sa.isa_tag&.isa_sample_characteristic? }
      input_attribute = sample_type.sample_attributes.detect(&:input_attribute?)
      sample_type.samples.map do |s|
        # To Do: FactorValues is empty. This relates to # 1869: https://github.com/seek4science/seek/issues/1869
        if s.can_view?(@current_user)
          {
            '@id': "#sample/#{s.id}",
            name: s.get_attribute_value(with_tag_sample),
            derivesFrom: extract_sample_ids(s.get_attribute_value(input_attribute), 'source'),
            characteristics: convert_characteristics(s, with_tag_sample_characteristic),
            factorValues: [
              {
                category: {
                  '@id': ''
                },
                value: {
                  annotationValue: '',
                  termSource: '',
                  termAccession: ''
                },
                unit: get_unit
              }
            ]
          }
        else
          {
            '@id': "#sample/HIDDEN",
            name: '',
            derivesFrom: extract_sample_ids(s.get_attribute_value(input_attribute), 'source'),
            characteristics: [],
            factorValues: [
              {
                category: {
                  '@id': ''
                },
                value: {
                  annotationValue: '',
                  termSource: '',
                  termAccession: ''
                },
                unit: { termSource: '', termAccession: '', comments: [] }
              }
            ]
          }
        end
      end
    end

    def convert_characteristics(sample, attributes)
      attributes.map do |attribute|
        value = convert_attribute_value(sample, attribute)
        ontology = get_ontology_details(attribute, value, true)
        {
          category: {
            '@id': normalize_id("#characteristic_category/#{attribute.title}_#{attribute.id}")
          },
          value: {
            annotationValue: value,
            termSource: ontology[:termSource],
            termAccession: ontology[:termAccession]
          },
          unit: get_unit
        }
      end
    end

    def convert_attribute_value(sample, attribute)
      return '' unless sample.can_view?(@current_user)

      if attribute.sample_attribute_type.seek_sample? || attribute.sample_attribute_type.seek_sample_multi? || attribute.sample_attribute_type.seek_strain? || attribute.sample_attribute_type.seek_data_file? || attribute.sample_attribute_type.seek_sop?
        sample.get_attribute_value(attribute).to_json || ''
      elsif attribute.sample_attribute_type.base_type == Seek::Samples::BaseType::CV_LIST
        sample.get_attribute_value(attribute).join(', ')
      else
        sample.get_attribute_value(attribute) || ''
      end
    end

    def convert_characteristic_categories(study = nil, assays = nil)
      attributes = []
      if study
        attributes = study.sample_types.map(&:sample_attributes).flatten
        attributes =
          attributes.select { |sa| sa.isa_tag&.isa_source_characteristic? || sa.isa_tag&.isa_sample_characteristic? }
      elsif assays
        attributes = assays.map { |a| a.sample_type.sample_attributes }.flatten
        attributes = attributes.select { |sa| sa.isa_tag&.isa_other_material_characteristic? }
      end
      attributes.map do |s|
        # Check if the sample_attribute title is an ontology term
        ontology = s.pid.present? ? get_ontology_details(s, s.title, false) : { termAccession: '', termSource: '' }
        {
          '@id': normalize_id("#characteristic_category/#{s.title}_#{s.id}"),
          characteristicType: {
            annotationValue: s.title,
            termAccession: ontology[:termAccession],
            termSource: ontology[:termSource]
          }
        }
      end
    end

    def convert_process_sequence(sample_type, protocols_map)
      # This method is meant to be used for both Studies and Assays
      return [] unless sample_type.samples.any?

      isa_parameter_value_attributes = select_parameter_values(sample_type)
      protocol_attribute = detect_protocol(sample_type)
      type = 'source'
      type = get_derived_from_type(sample_type) if sample_type.assays.any?

      # Convention : The sample_types of studies don't have assay
      # This make a process sequence per sample. Same inputs that generate one output should be bundled.
      # One input used for multiple outputs should be bundled as well.
      # In SEEK parameter_values are sample specific but outputs, linked to the same input, with different parameter_values
      # should be in a different process in the processSequence
      samples_grouped_by_input_and_parameter_value = group_samples_by_input_and_parameter_value(sample_type)
      result = []
      samples_grouped_by_input_and_parameter_value.map do |sample_group|
        # It's fine to take the first output to get the protocol name since the outputs are grouped by protocol as well.
        protocols, isa, isa_id, _sample_type_id = protocols_map.values_at(:protocols, :isa, :isa_id, :sample_type_id)
        executed_protocol = protocols_map[:protocols].detect { |p| p[:name] == sample_group[:executed_protocol][:title] }
        output_ids = sample_group[:outputs].map { |s| s[:id] }.join('_')
        process = {
          '@id': normalize_id("#process/#{protocol_attribute.title}/#{output_ids}"),
          name: '',
          executesProtocol: {
            '@id': executed_protocol["@id"]
          },
          parameterValues: convert_parameter_values(sample_group[:outputs], isa_parameter_value_attributes),
          performer: '',
          date: '',
          inputs: process_sequence_input(sample_group[:inputs], type),
          outputs: process_sequence_output(sample_group[:outputs])
        }
        # Study processes don't have a previousProcess and nextProcess
        unless type == 'source'
          process.merge!({
                           previousProcess: previous_process(sample_group[:outputs]),
                           nextProcess: next_process(sample_group[:outputs])
                         })
        end
        result.push(process)
      end
      result
    end

    def convert_data_files(sample_types)
      st = sample_types.detect { |s| detect_data_file(s) }
      return [] unless st

      with_tag_data_file = detect_data_file(st)
      with_tag_data_file_comment = select_data_file_comment(st)
      return [] unless with_tag_data_file

      st.samples.map do |s|
        if s.can_view?(@current_user)
          {
            '@id': "#data_file/#{s.id}",
            name: s.get_attribute_value(with_tag_data_file),
            type: with_tag_data_file.title,
            comments: with_tag_data_file_comment.map { |d| { name: d.title, value: s.get_attribute_value(d).to_s } }
          }
        else
          {
            '@id': "#data_file/HIDDEN",
            name: 'HIDDEN',
            type: with_tag_data_file.title,
            comments: []
          }
        end
      end
    end

    def convert_other_materials(sample_types)
      isa_other_material_sample_types =
        sample_types.select { |s| s.sample_attributes.detect { |sa| sa.isa_tag&.isa_other_material? } }

      other_materials = []
      isa_other_material_sample_types.each do |st|
        with_tag_isa_other_material = st.sample_attributes.detect { |sa| sa.isa_tag&.isa_other_material? }
        return [] unless with_tag_isa_other_material

        seek_sample_multi_attribute = st.sample_attributes.detect(&:seek_sample_multi?)
        raise 'Defective ISA other_materials!' unless seek_sample_multi_attribute

        with_tag_isa_other_material_characteristics =
          st.sample_attributes.select { |sa| sa.isa_tag&.isa_other_material_characteristic? }

        type = get_derived_from_type(st)
        raise 'Defective ISA process_sequence!' unless type

        other_materials +=
          st
            .samples
            .map do |s|
              if s.can_view?(@current_user)
                {
                  '@id': "#other_material/#{s.id}",
                  name: s.get_attribute_value(with_tag_isa_other_material),
                  type: with_tag_isa_other_material.title,
                  characteristics: convert_characteristics(s, with_tag_isa_other_material_characteristics),
                  # It can sometimes be other_material or sample!!!! SHOULD BE DYNAMIC
                  derivesFrom: extract_sample_ids(s.get_attribute_value(seek_sample_multi_attribute), type)
                }
              else
                {
                  '@id': "#other_material/HIDDEN",
                  name: 'HIDDEN',
                  type: with_tag_isa_other_material.title,
                  characteristics: convert_characteristics(s, with_tag_isa_other_material_characteristics),
                  # It can sometimes be other_material or sample!!!! SHOULD BE DYNAMIC
                  derivesFrom: extract_sample_ids(s.get_attribute_value(seek_sample_multi_attribute), type)
                }
              end
            end
            .flatten
      end
      other_materials
    end

    def assay_samples(first_assay)
      first_assay.samples.map { |s| find_sample_origin([s], 1) }.flatten.uniq.map { |s| { '@id': "#sample/#{s}" } }
    end

    def export
      convert_investigation
      @OBJECT_MAP.to_json
    end

    private

    def detect_material(sample_type)
      sample_type.sample_attributes.detect do |sa|
        [
          Seek::ISA::TagType::SOURCE,
          Seek::ISA::TagType::SAMPLE,
          Seek::ISA::TagType::OTHER_MATERIAL
        ].include? sa.isa_tag&.title
      end
    end
    def detect_sample(sample_type)
      sample_type.sample_attributes.detect { |sa| sa.isa_tag&.isa_sample? }
    end

    def detect_source(sample_type)
      sample_type.sample_attributes.detect { |sa| sa.isa_tag&.isa_source? }
    end

    def detect_protocol(sample_type)
      sample_type.sample_attributes.detect { |sa| sa.isa_tag&.isa_protocol? }
    end

    def select_parameter_values(sample_type)
      sample_type.sample_attributes.select { |sa| sa.isa_tag&.isa_parameter_value? }
    end

    def detect_data_file(sample_type)
      sample_type.sample_attributes.detect { |sa| sa.isa_tag&.isa_data_file? }
    end

    def select_data_file_comment(sample_type)
      sample_type.sample_attributes.select { |sa| sa.isa_tag&.isa_data_file_comment? }
    end

    def detect_other_material(sample_type)
      sample_type.sample_attributes.detect { |sa| sa.isa_tag&.isa_other_material? }
    end

    def detect_input_attribute(sample_type)
      sample_type.sample_attributes.detect(&:input_attribute?)
    end

    def next_process(samples_hash)
      # return {} for studies
      sample = Sample.find(samples_hash.first[:id])
      return {} if sample.sample_type.assays.blank?

      sample_type = sample.linking_samples.first&.sample_type
      if sample_type
        protocol = detect_protocol(sample_type)
        return { '@id': normalize_id("#process/#{detect_protocol(sample_type).title}/#{sample.id}") } if protocol
      end
      return {}
    end

    def previous_process(samples_hash)
      sample = Sample.find(samples_hash.first[:id])

      sample_type = sample.linked_samples.first&.sample_type
      if (sample_type)
        protocol = detect_protocol(sample_type)
        if (protocol)
          # if there's no protocol, it means the previous sample type is source
          return { '@id': normalize_id("#process/#{protocol.title}/#{sample.id}") }
        end
      end
      return {}
    end

    def group_id(key)
      key[0] = key[0].map { |input| { id: input['id'] } }
      key
    end

    def group_samples_by_input_and_parameter_value(sample_type)
      samples = sample_type.samples
      samples_metadata = samples.map do |sample|
        metadata = JSON.parse(sample.json_metadata)

        {
          'id': sample.id,
          'title': sample.title
        }.merge(metadata).transform_keys!(&:to_sym)
      end

      input_attribute_name = detect_input_attribute(sample_type)&.title&.to_sym
      parameter_value_attribute_names = select_parameter_values(sample_type).map(&:title).map(&:to_sym)
      protocol_attribute_name = detect_protocol(sample_type)&.title&.to_sym
      material_attribute_name = detect_material(sample_type)&.title&.to_sym
      group_attribute_names = parameter_value_attribute_names.unshift(protocol_attribute_name).unshift(input_attribute_name)

      # grouped_samples = samples_metadata.group_by { |smd| group_attributes.map { |attr| smd[attr] } }
      sample_groups = samples_metadata.group_by { |smd| group_attribute_names.map { |attr| smd[attr] }.flatten }.map { |_key, val| val }

      sample_groups.map do |sample_group|
        inputs = sample_group.first[input_attribute_name]
        executed_protocol = detect_protocol(sample_type).sample_attribute_type.seek_sop? ? sample_group.first[protocol_attribute_name] : { id: detect_protocol(sample_type)&.id, title: sample_group.first[protocol_attribute_name] }
        parameter_values = sample_group.first.slice(*parameter_value_attribute_names)
        outputs = sample_group.map { |sample| {id: sample[:id], title: sample[material_attribute_name] } }
        {
          inputs: inputs.map { |input| input.transform_keys!(&:to_sym) },
          executed_protocol: executed_protocol.transform_keys!(&:to_sym),
          parameter_values: parameter_values.transform_keys!(&:to_sym),
          outputs: outputs.map { |input| input.transform_keys!(&:to_sym) }
        }
      end
    end

    def process_sequence_input(inputs, type)
      input_ids = inputs.map { |input| input[:id] }
      authorized_sample_ids = Sample.where(id: input_ids).authorized_for(:view, @current_user).map(&:id)
      input_ids.map do |input_id|
        if authorized_sample_ids.include?(input_id)
          { '@id': "##{type}/#{input_id}" }
        else
          { '@id': "##{type}/HIDDEN" }
        end
      end
    end

    def process_sequence_output(samples_hash)
      prefix = 'sample'
      samples_hash.map do |sample_hash|
        sample = Sample.find(sample_hash[:id])
        if sample.sample_type.isa_template.level.include?('assay')
          if detect_other_material(sample.sample_type)
            prefix = 'other_material'
          elsif detect_data_file(sample.sample_type)
            prefix = 'data_file'
          else
            raise 'Defective ISA process!'
          end
        end
        if sample.can_view?(@current_user)
          { '@id': "##{prefix}/#{sample.id}" }
        else
          { '@id': "##{prefix}/HIDDEN" }
        end
      end
    end

    def convert_parameter_values(sample_group_hash, isa_parameter_value_attributes)
      # Every sample in the group should has the same parameterValue.
      # So retrieving the first one in the group should be fine.
      sample = Sample.find(sample_group_hash.first[:id])
      isa_parameter_value_attributes.map do |p|
        value = convert_attribute_value(sample, p)
        ontology = get_ontology_details(p, value, true)
        {
          category: {
            '@id': "#parameter/#{p.id}"
          },
          value: {
            annotationValue: value,
            termSource: ontology[:termSource],
            termAccession: ontology[:termAccession]
          },
          unit: get_unit
        }
      end
    end

    def extract_sample_ids(input_obj_list, type)
      sample_ids = input_obj_list.map { |io| io[:id] }
      authorized_sample_ids = Sample.where(id: sample_ids).authorized_for(:view, @current_user).map(&:id)

      sample_ids.map do |s_id|
        if authorized_sample_ids.include?(s_id)
          { '@id': "##{type}/#{s_id}" }
        else
          { '@id': "##{type}/HIDDEN" }
        end
      end
    end

    def get_ontology_details(sample_attribute, label, vocab_term)
      is_ontology = sample_attribute.ontology_based?
      iri = ''
      if is_ontology
        iri =
          if vocab_term
            sample_attribute.sample_controlled_vocab.sample_controlled_vocab_terms.find_by_label(label)&.iri
          else
            sample_attribute.sample_controlled_vocab.ols_root_term_uris
          end
      end
      term_accession = iri || ''
      termSource = term_accession.present? ? sample_attribute.sample_controlled_vocab.source_ontology : ''
      { termAccession: term_accession, termSource: termSource }
    end

    # This method finds the source sample (sample_collection/samples of 2nd sample_type of the study) of a sample
    # The samples declared in the study level and being used in the stream of the current sample
    def find_sample_origin(sample_list, level)
      sample_array = []
      while sample_list.any?
        temp = []
        sample_list.each { |sample| temp += sample.linked_samples.order(:id) if sample.linked_samples.any? }
        sample_array << temp.map { |s| s.id }.uniq if !temp.blank?
        sample_list = temp
      end
      sample_array[sample_array.length - level - 1]
    end

    def random_string(len)
      (0...len).map { ('a'..'z').to_a[rand(26)] }.join
    end

    def get_derived_from_type(sample_type)
      raise "There are no samples in '#{sample_type.title}'!" if sample_type.samples.blank?

      prev_sample_type = sample_type.samples[0]&.linked_samples[0]&.sample_type
      return nil if prev_sample_type.blank?

      if detect_source(prev_sample_type)
        'source'
      elsif detect_sample(prev_sample_type)
        'sample'
      elsif detect_other_material(prev_sample_type)
        'other_material'
      elsif detect_data_file(prev_sample_type)
        'data_file'
      end
    end

    def normalize_id(str)
      str.tr!(' ', '_') || str
    end

    def get_unit
      { termSource: '', termAccession: '', comments: [] }
    end
  end
end
