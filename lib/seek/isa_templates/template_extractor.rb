require 'json-schema'
# singleton class for extracting Templates and their attributes from json files
module Seek
  module IsaTemplates
    module TemplateExtractor
      def self.extract_templates
        `touch #{resultfile}`
        result = StringIO.new

        seed_isa_tags

        disable_authorization_checks do
          client = Ebi::OlsClient.new
          project = Project.find_or_create_by(title: 'Default Project')
          directory = Rails.root.join('config', 'default_data', 'source_types')
          directory_files = Dir.exist?(directory) ? Dir.glob("#{directory}/*.json") : []
          raise '<ul><li>Make sure to upload files that have the ".json" extension.</li></ul>' if directory_files == []

          directory_files.each do |filename|
            puts filename
            next if File.extname(filename) != '.json'

            file = File.read(filename)
            res = check_json_file(file)
            raise res if res.present?

            data_hash = JSON.parse(file)
            data_hash['data'].each do |item|
              template_details = init_template(item['metadata'])

              if template_exists?(template_details)
                result << add_log(template_details, 'Skipped')
                next
              else
                result << add_log(template_details, 'Created')
              end

              template = Template.create(template_details.merge({ projects: [project], policy: Policy.public_policy }))

              item['data'].each_with_index do |attribute, j|
                is_ontology = attribute['ontology'].present?
                is_cv = attribute['CVList'].present?
                if is_ontology || is_cv
                  scv =
                    SampleControlledVocab.new(
                      {
                        title: attribute['name'],
                        source_ontology: is_ontology ? attribute['ontology']['name'] : nil,
                        ols_root_term_uri: is_ontology ? attribute['ontology']['rootTermURI'] : nil,
                        custom_input: true
                      }
                    )
                end

                if is_ontology
                  if attribute['ontology']['rootTermURI'].present?
                    begin
                      terms = client.all_descendants(attribute['ontology']['name'],
                                                     attribute['ontology']['rootTermURI'])
                    rescue Exception => e
                      scv.save(validate: false)
                      next
                    end
                    terms.each_with_index do |term, i|
                      puts "#{j}) #{i + 1} FROM #{terms.length}"
                      if i.zero?
                        # Skip the parent name
                        des = term[:description]
                        scv[:description] = des.is_a?(Array) ? des[0] : des
                      elsif term[:label].present? && term[:iri].present?
                        cvt =
                          SampleControlledVocabTerm.new(
                            { label: term[:label], iri: term[:iri], parent_iri: term[:parent_iri] }
                          )
                        scv.sample_controlled_vocab_terms << cvt
                      end
                    end
                  end
                elsif is_cv
                  # the CV terms
                  if attribute['CVList'].present?
                    attribute['CVList'].each do |term|
                      cvt = SampleControlledVocabTerm.new({ label: term })
                      scv.sample_controlled_vocab_terms << cvt
                    end
                  end
                end

                p scv.errors if (is_ontology || is_cv) && !scv.save(validate: false)

                template_attribute_details = { title: attribute['name'], template_id: template.id }

                TemplateAttribute.create(template_attribute_details.merge({
                                                                            is_title: attribute['title'] || 0,
                                                                            isa_tag_id: get_isa_tag_id(attribute['isaTag']),
                                                                            short_name: attribute['short_name'],
                                                                            required: attribute['required'],
                                                                            description: attribute['description'],
                                                                            sample_controlled_vocab_id: scv&.id,
                                                                            pid: attribute['pid'],
                                                                            sample_attribute_type_id: get_sample_attribute_type(attribute['dataType'])
                                                                          }))
              end
            end
          end
        end
        write_result(result.string)
      rescue Exception => e
        puts e
        write_result("error(s): #{e}")
      ensure
        `rm -f #{lockfile}`
      end

      def self.init_template(metadata)
        {
          title: metadata['name'],
          group: metadata['group'],
          group_order: metadata['group_order'],
          temporary_name: metadata['temporary_name'],
          version: metadata['version'],
          isa_config: metadata['isa_config'],
          isa_measurement_type: metadata['isa_measurement_type'],
          isa_technology_type: metadata['isa_technology_type'],
          isa_protocol_type: metadata['isa_protocol_type'],
          repo_schema_id: metadata['r epo_schema_id'],
          organism: metadata['organism'],
          level: metadata['level']
        }
      end

      def self.write_result(result)
        File.open(resultfile, 'w') { |file| file.write result }
      end

      def self.template_exists?(template_details)
        Template.find_by(title: template_details[:title], group: template_details[:group],
                         version: template_details[:version]).present?
      end

      def self.add_log(template_details, type)
        "<li>#{type} >> <b>#{template_details[:title]}</b>, Group: <b>#{template_details[:group]}</b>, Version: <b>#{template_details[:version]}</b></li>"
      end

      def self.check_json_file(file)
        res = valid_isa_json?(file)
        res.map { |r| "<li>#{r}</li>" }.join('')
      end

      def self.valid_isa_json?(json)
        definitions_path =
          File.join(Rails.root, 'lib', 'seek', 'isa_templates', 'template_schema.json')
        if File.readable?(definitions_path)
          JSON::Validator.fully_validate_json(definitions_path, json)
        else
          ['The schema file is not readable!']
        end
      end

      def self.get_sample_attribute_type(title)
        SampleAttributeType.where(title: title).first.id
      end

      def self.get_isa_tag_id(title)
        return nil if title.blank?

        IsaTag.where(title: title).first.id
      end

      def self.seed_isa_tags
        Rake::Task['db:seed:015_isa_tags'].invoke if IsaTag.all.blank?
      end

      def self.lockfile
        Rails.root.join('tmp', 'populate_templates.lock')
      end

      def self.resultfile
        Rails.root.join('tmp', 'populate_templates.result')
      end
    end
  end
end
