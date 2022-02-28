# noinspection ALL
module IsaExporter
    class Exporter

        def initialize(investigation)
            @investigation = investigation
            @OBJECT_MAP = Hash.new
        end

        def convert_investigation
            isa_investigation = {}
            isa_investigation[:identifier] = nil # @investigation.id
            isa_investigation[:title] = @investigation.title
            isa_investigation[:description] = @investigation.description
            isa_investigation[:submissionDate] = nil #@investigation.created_at.to_date.iso8601
            isa_investigation[:publicReleaseDate] = nil #@investigation.created_at.to_date.iso8601
            isa_investigation[:ontologySourceReferences] = convert_ontologies

            publications = []
            @investigation.publications.each do |p|
                publications << convert_publication(p)
            end
            isa_investigation[:publications] = publications
        
            people = []
            @investigation.related_people.each do |p|
                people << convert_person(p)
            end
            isa_investigation[:people] = people
        
            studies = []
            @investigation.studies.each do |s|
                studies << convert_study(s)
            end
            isa_investigation[:studies] = studies
        
            @OBJECT_MAP[:investigation] = isa_investigation
        
            return isa_investigation
        end
    
        def convert_study (study)
            isa_study = {}
            isa_study[:identifier] = study.id
            isa_study[:title] = study.title
            isa_study[:description] = study.description
            isa_study[:submissionDate] = study.created_at.to_date.iso8601
            isa_study[:publicReleaseDate] = study.created_at.to_date.iso8601
            isa_study[:filename] = nil
        
            publications = []
            study.publications.each do |p|
                publications << convert_publication(p)
            end
            isa_study[:publications] = publications
        
            people = []
            study.related_people.each do |p|
                people << convert_person(p)
            end
            isa_study[:people] = people
            isa_study[:studyDesignDescriptors] = []
            isa_study[:characteristicCategories] = convert_characteristic_categories(study)
            isa_study[:materials] = { 
                sources: convert_materials_sources(study.sample_types.first), 
                samples: convert_materials_samples(study.sample_types.second)
            }

            isa_study[:processSequence] = convert_process_sequence(study.sample_types.second)

            protocols = []
            study.assays.each do |a|
                # There should be only one attribute with isa_tag == protocol
                with_tag_protocol = a.sample_type.sample_attributes.detect { |sa| sa.isa_tag&.isa_protocol? }
                with_tag_parameter_value = a.sample_type.sample_attributes.select { |sa| sa.isa_tag&.isa_parameter_value? }
                raise "Protocol ISA tag not found in assay #{a.id}" if with_tag_protocol.blank?
                sop = a.sops.first
                protocols << convert_protocol(sop, with_tag_protocol, with_tag_parameter_value)
            end
            isa_study[:protocols] = protocols

            assays = []
            study.assays.each do |a|
                assays << convert_assay(a)
            end
            isa_study[:assays] = assays

            isa_study[:factors] = []
            isa_study[:unitCategories] = []

            return isa_study
        end
    
        def convert_annotation(term_uri)
            isa_annotation = {}
            term = term_uri.split('#')[1]
            isa_annotation[:annotationValue] = term
            isa_annotation[:termAccession] = term_uri
            isa_annotation[:termSource] = 'jerm_ontology'
            return isa_annotation
        end
    
        def convert_assay (assay)
            isa_assay = {}
            isa_assay["@id"] = "#assay/#{assay.id}"
            isa_assay[:filename] = assay&.sample_type&.isa_template&.title
            isa_assay[:measurementType] = {
                annotationValue: "",
                termSource: "",
                termAccession: ""
            }
            isa_assay[:technologyType] = {
                annotationValue: "",
                termSource: "",
                termAccession: ""
            }
            isa_assay[:technologyPlatform] = nil
            isa_assay[:characteristicCategories] = convert_characteristic_categories(nil, assay)
            isa_assay[:materials] = { 
                samples: assay.sample_type.samples.map { |s| find_sample_origin([s]) }.flatten.uniq.map{ |s| {"@id": "#sample/#{s}"} } ,#the samples from study level that are referenced in this assay's samples,
                otherMaterials: convert_other_materials(assay.sample_type),
            }
            isa_assay[:processSequence] = convert_process_sequence(assay.sample_type)
            isa_assay[:dataFiles] = convert_data_files(assay.sample_type)
            isa_assay[:unitCategories] = [{
                "@id": nil,
                annotationValue: nil,
                termSource: nil,
                termAccession: nil
            }]
            return isa_assay
        end
    
        def convert_person(person)
            isa_person = { "@id": "#people/#{person.id}" }
            isa_person[:lastName] = person.last_name
            isa_person[:firstName] = person.first_name
            isa_person[:midInitials] = ''
            isa_person[:email] = person.email
            isa_person[:phone] = person.phone
            isa_person[:fax] = nil
            isa_person[:address] = nil
            isa_person[:affiliation] = nil
            roles = {}
            roles[:termAccession] = ""
            roles[:termSource] = ""
            roles[:annotationValue] = ""
            isa_person[:roles] = [roles]
            isa_person[:comments] = [{
                "@id": nil ,
                value: nil,
                name: nil
            }]
            return isa_person
        end
    
        def convert_publication(publication)
            isa_publication = {}
            isa_publication[:pubMedID] = publication.pubmed_id
            isa_publication[:doi] = publication.doi
            status = {}
            status[:termAccession] = ""
            status[:termSource] = ""
            status[:annotationValue] = ""
            isa_publication[:status] = status
            isa_publication[:title] = publication.title
            isa_publication[:author_list] = publication.authors.map { |a| a.full_name }.join(', ')
        
            return publication
        end

        def convert_ontologies
            client = Ebi::OlsClient.new
            source_ontologies = []
            sample_types = @investigation.studies.map {|s| s.sample_types} + @investigation.assays.map {|a| a.sample_type}
            sample_types.flatten.each do |sa|
                sa.sample_attributes.each do |atr|
                    source_ontologies << atr.sample_controlled_vocab.source_ontology if atr.sample_attribute_type.ontology?
                end
            end
            source_ontologies.uniq.map { |s| client.fetch_ontology_reference(s) }
        end

        def convert_protocol(sop, protocol, parameter_values)
            isa_protocol = {}
            # generates random identifiers that point to the same resource in Seek
            isa_protocol['@id'] =  "#protocol/#{sop.id}?#{random_string(6)}"
            isa_protocol[:name] = protocol.title #sop.title

            ontology = get_ontology_details(protocol)

            isa_protocol[:protocolType] = {
                annotationValue: protocol.title,
                termAccession: ontology[:termAccession],
                termSource: ontology[:termSource]
            }
            isa_protocol[:description] = sop.description
            isa_protocol[:uri] = ontology[:termAccession]
            isa_protocol[:version] = nil
            isa_protocol[:parameters] = parameter_values.map do |parameter_value|
                parameter_value_ontology = get_ontology_details(parameter_value)
                {
                    "@id": "#parameter/#{parameter_value.id}",
                    parameterName: {
                        annotationValue: parameter_value.title,
                        termAccession: parameter_value_ontology[:termAccession],
                        termSource: parameter_value_ontology[:termSource]
                    }
                }
            end
            isa_protocol[:components] = [
                {
                    componentName: "",
                    componentType: {
                        annotationValue: "",
                        termSource: "",
                        termAccession: ""
                    }
                }
            ]

            return isa_protocol
        end

        def convert_materials_sources(sample_type)
            with_tag_source = sample_type.sample_attributes.detect { |sa| sa.isa_tag&.isa_source? }
            with_tag_source_characteristic = sample_type.sample_attributes.select { |sa| sa.isa_tag&.isa_source_characteristic? }
            sources = sample_type.samples.map do |s|
                {
                    "@id": "#source/#{s.id}",
                    name: s.get_attribute_value(with_tag_source),
                    characteristics: convert_characteristics(s, with_tag_source_characteristic)   
                }
            end
            sources
        end

        def convert_materials_samples(sample_type)
            with_tag_sample = sample_type.sample_attributes.detect { |sa| sa.isa_tag&.isa_sample? }
            with_tag_sample_characteristic = sample_type.sample_attributes.select{ |sa| sa.isa_tag&.isa_sample_characteristic? }
            with_type_seek_sample_multi = sample_type.sample_attributes.detect(&:seek_sample_multi?)
            samples = sample_type.samples.map do |s|
                {
                    "@id": "#sample/#{s.id}",
                    name: s.get_attribute_value(with_tag_sample),
                    derivesFrom: extract_sample_ids(s.get_attribute_value(with_type_seek_sample_multi), "source"),
                    characteristics: convert_characteristics(s, with_tag_sample_characteristic),
                    factorValues: [{
                        category: { "@id": nil },
                        value: {
                            annotationValue: nil,
                            termSource: nil,
                            termAccession: nil
                        },
                        unit: { "@id": nil }
                    }]
                }
            end
            samples
        end
        
        def convert_characteristics(sample, with_tag_source_characteristic)
            with_tag_source_characteristic.map do |c|
                ontology = get_ontology_details(c)
                return {
                    category: { "@id": "#characteristic_category/#{c.title}" },
                    value: {
                        annotationValue: sample.get_attribute_value(c),
                        termSource: ontology[:termSource],
                        termAccession: ontology[:termAccession]
                    },
                    unit: { "@id": nil }
                }
            end
        end

        def convert_characteristic_categories(study = nil, assay = nil)
            attributes = []
            if study
                attributes = study.sample_types.map{ |s| s.sample_attributes }.flatten
                attributes = attributes.select{ |sa| sa.isa_tag&.isa_source_characteristic? || sa.isa_tag&.isa_sample_characteristic? }
            elsif assay
                attributes = assay.sample_type.sample_attributes
                attributes = attributes.select{ |sa| sa.isa_tag&.isa_other_material_characteristic? }
            end
            attributes.map do |s|
                ontology = get_ontology_details(s)
                {
                    "@id": "#characteristic_category/#{s.id}",
                    characteristicType: {
                        annotationValue: s.title,
                        termAccession: ontology[:termAccession],
                        termSource: ontology[:termSource]
                    }
                }
            end
        end

        def convert_process_sequence(sample_type)
            # This method is meant to be used for both Studies and Assays
            return [] if !sample_type.samples.any?
            with_tag_isa_parameter_value = get_values(sample_type)
            with_tag_protocol = detect_protocol(sample_type)
            with_type_seek_sample_multi = detect_sample_multi(sample_type)
            type = "source"
            if sample_type.assays.any?
                prev_sample_type = sample_type.samples[0].linked_samples[0].sample_type
                if detect_sample(prev_sample_type)
                    type = "sample"
                elsif detect_other_material(prev_sample_type)
                    type = "otherMaterials"
                elsif detect_data_file(prev_sample_type)
                    type = "dataFile"
                end
                raise "Defected ISA process_sequence!" if !type
            end
            sample_type.samples.map do |s|
                {
                    "@id": "#process/#{with_tag_protocol.title}/#{s.id}", 
                    name: nil,
                    executesProtocol: {
                        "@id": "#protocol/#{with_tag_protocol.id}"
                    },
                    parameterValues: convert_parameter_values(s, with_tag_isa_parameter_value),
                    performer:"",
                    date:"",
                    previousProcess: previous_process(s),
                    nextProcess: next_process(s),
                    inputs: extract_sample_ids(s.get_attribute_value(with_type_seek_sample_multi), type),
                    outputs: process_sequence_output(s)
                }
            end
        end

        def convert_data_files(sample_type)
            with_tag_data_file = detect_data_file(sample_type)
            return [] if !with_tag_data_file
            sample_type.samples.map do |s|
                {
                    "@id": "#data/#{s.id}",
                    name: s.get_attribute_value(with_tag_data_file),
                    type: with_tag_data_file.title,
                    comments: []
                }
            end
        end

        def convert_other_materials(sample_type)
            with_tag_isa_other_material = detect_other_material(sample_type)
            return [] if !with_tag_isa_other_material
            with_type_seek_sample_multi = detect_sample_multi(sample_type)
            raise "Defected ISA other_materials!" if !with_type_seek_sample_multi
            sample_type.samples.map do |s|
                {
                    "@id": "#material/#{s.id}", 
                    name: s.get_attribute_value(with_tag_isa_other_material),
                    type: with_tag_isa_other_material.title,
                    characteristics: [
                        {
                            category: { "@id": nil },
                            value: {
                                annotationValue: nil,
                                termSource: nil,
                                termAccession: nil
                            },
                            unit: { "@id": nil }
                        }
                    ],
                    derivesFrom: extract_sample_ids(s.get_attribute_value(with_type_seek_sample_multi), "sample")
                }
            end
        end
    
        def export
            convert_investigation()
            return @OBJECT_MAP.to_json
        end



        private 

        def detect_sample(sample_type)
            sample_type.sample_attributes.detect{ |sa| sa.isa_tag&.isa_sample? }
        end

        def detect_protocol(sample_type)
            sample_type.sample_attributes.detect{ |sa| sa.isa_tag&.isa_protocol? }
        end

        def get_values(sample_type)
            sample_type.sample_attributes.select{|sa| sa.isa_tag&.isa_parameter_value?}
        end

        def detect_data_file(sample_type)
            sample_type.sample_attributes.detect{|sa| sa.isa_tag&.isa_data_file?}
        end

        def detect_other_material(sample_type)
            sample_type.sample_attributes.detect{|sa| sa.isa_tag&.isa_other_material?}
        end

        def detect_sample_multi(sample_type)
            sample_type.sample_attributes.detect(&:seek_sample_multi?)
        end

        def next_process(sample)
            # return { "@id": nil } for studies
            return { "@id": nil } if sample.sample_type.assays.blank?
            sample_type = sample.linking_samples.first&.sample_type
            return nil if !sample_type
            protocol = detect_protocol(sample_type)
            return sample_type && protocol ? { "@id": "#process/#{detect_protocol(sample_type).title}" } : nil
        end

        def previous_process(sample)
            sample_type = sample.linked_samples.first&.sample_type
            return nil if !sample_type
            protocol = detect_protocol(sample_type)
            # if there's no protocol, it means the previous sample type is source
            return sample_type && protocol ?  { "@id": "#process/#{protocol.title}" } : nil
        end

        def process_sequence_output(sample)
            prefix = "sample"
            if sample.sample_type.isa_template.level == "assay"
                if detect_other_material(sample.sample_type)
                    prefix = "other_material"
                else
                    if detect_data_file(sample.sample_type)
                        prefix = "data_file"
                    else
                        raise "Defected ISA process!"
                    end
                end
            end
            return {"@id": "##{prefix}/#{sample.id}"}
        end

        def convert_parameter_values(sample, with_tag_isa_parameter_value)
            with_tag_isa_parameter_value.map do |p|
                ontology = get_ontology_details(p)
                {
                    category: {
                        "@id": "#parameter/#{p.id}"
                    },
                    value: {
                        annotationValue: sample.get_attribute_value(p),
                        termSource: ontology[:termSource],
                        termAccession: ontology[:termAccession]
                    },
                    unit: {
                        "@id": "#unit/?"
                    }
                }
            end
        end

        def extract_sample_ids(obj, type)
            Array.wrap(obj).map { |item| {"@id": "##{type}/#{item[:id]}"} }
        end

        def get_ontology_details(sample_attribute)
            is_ontology = sample_attribute.sample_attribute_type.ontology?
            return {
                termAccession: is_ontology ? sample_attribute.sample_controlled_vocab.ols_root_term_uri : nil,
                termSource: is_ontology ? sample_attribute.sample_controlled_vocab.source_ontology : nil
            }
        end

        # This method finds the source sample (sample_collection/samples of 2nd sample_type of the study) of a sample
        # The samples declared in the study level and being used in the stream of the current sample
        def find_sample_origin(sample_list)
            temp = []
            while sample_list.any? do
              sample_list = sample_list.map{ |s| s.linked_samples }.flatten.uniq
              temp << sample_list.map{ |s| s.id }
            end
            #temp[0]: source, temp[1]: sample
            return temp[0]
        end

        def random_string(len)
            (0...len).map { ('a'..'z').to_a[rand(26)] }.join
        end


    end  
end
  