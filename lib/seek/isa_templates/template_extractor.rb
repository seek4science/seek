require 'json-schema'
# singleton class for extracting Templates and their attributes from json files
module Seek
  module ISATemplates
    module TemplateExtractor
      def self.extract_templates(user)
        FileUtils.touch(resultfile)
        result = StringIO.new
        seed_isa_tags

        User.with_current_user(user) do
          project = Project.find_or_create_by(title: 'Default Project')
          directory = Seek::Config.append_filestore_path('source_types')
          @directory_files = Dir.exist?(directory) ? Dir.glob("#{directory}/*.json") : []
          raise '<ul><li>Make sure to upload files that have the ".json" extension.</li></ul>' if @directory_files == []

          @directory_files.each do |filename|
            next if File.extname(filename) != '.json'

            @errors = []
            file = File.read(filename)
            res = check_json_file(file)
            @errors.append res if res.present?

            data_hash = JSON.parse(file)
            data_hash['data'].each do |item|
              template_details = init_template(item['metadata'])

              if template_exists?(template_details)
                result << add_log(template_details, 'Skipped')
                next
              else
                result << add_log(template_details, 'Created')
              end

              template = Template.new(template_details.merge({ projects: [project], policy: Policy.public_policy }))

              current_template_attributes = []
              item['data'].each_with_index do |attribute, j|
                is_cv = attribute['dataType'].include? 'Controlled Vocabulary'
                allow_cv_free_text = false
                if is_cv
                  is_ontology = attribute['ontology'].present?
                  cv_exists = !SampleControlledVocab.find_by(title: attribute['name']).nil?
                  allow_cv_free_text = attribute['allowCVFreeText'].present? ? attribute['allowCVFreeText'] : false

                  scv = cv_exists ? SampleControlledVocab.find_by(title: attribute['name']) : initialize_sample_controlled_vocab(template_details, attribute, is_ontology)
                end
                p scv.errors if is_cv && !scv.save(validate: false)

                ta = TemplateAttribute.new(is_title: (attribute['title'] || 0),
                                     isa_tag_id: get_isa_tag_id(attribute['isaTag']),
                                     short_name: attribute['short_name'],
                                     required: attribute['required'],
                                     description: attribute['description'],
                                     sample_controlled_vocab_id: scv&.id,
                                     pid: attribute['pid'],
                                     sample_attribute_type_id: get_sample_attribute_type(attribute['dataType']),
                                     allow_cv_free_text: allow_cv_free_text,
                                     title: attribute['name'])

                current_template_attributes.append ta
              end
              template.template_attributes << current_template_attributes
              template.contributor = nil
              template.save! unless @errors.present?
            end

            # Remove the file after processing
          end
        end
        raise "<ul>#{@errors.map { |e| "#{e}" }.join('')}</ul>".html_safe if @errors.present?

        write_result(result.string)
      rescue StandardError => e
        write_result("error(s): #{e}")
        raise e
      ensure
        FileUtils.rm_f(lockfile)
        FileUtils.rm_f(@directory_files) unless @directory_files.blank?
      end

      def self.initialize_sample_controlled_vocab(template_details, attribute, is_ontology = false)
        scv = SampleControlledVocab.new(
          {
            title: attribute['name'],
            source_ontology: is_ontology ? attribute['ontology']['name'] : nil,
            ols_root_term_uris: is_ontology ? attribute['ontology']['rootTermURI'] : nil
          }
        )

        if is_ontology
          client = Ebi::OlsClient.new
          if attribute['ontology']['rootTermURI'].present?
            begin
              terms = client.all_descendants(attribute['ontology']['name'],
                                             attribute['ontology']['rootTermURI'])
            rescue StandardError => e
              add_log(template_details, "Failed to fetch terms from OLS for attribute '#{attribute['name']}'. Please add terms manually!")
              Rails.logger.debug("Failed to fetch terms from OLS for attribute '#{attribute['name']}'. Error: #{e}")
              terms = []
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
        else
          # the CV terms
          attribute['CVList'].each do |term|
            cvt = SampleControlledVocabTerm.new({ label: term })
            scv.sample_controlled_vocab_terms << cvt
          end
        end
        scv
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
        # read the schema file depending on the environment
        definitions_path = if Rails.env.test?
                             File.join(Rails.root, 'lib', 'seek', 'isa_templates', 'template_schema_test.json')
                           else
                             File.join(Rails.root, 'lib', 'seek', 'isa_templates', 'template_schema.json')
                           end

        if File.readable?(definitions_path)
          JSON::Validator.fully_validate_json(definitions_path, json)
        else
          ['The schema file is not readable!']
        end
      end

      def self.get_sample_attribute_type(title)
        sa = SampleAttributeType.find_by(title: title)
        @errors.append "<li>Could not find a Sample Attribute Type named '#{title}'</li>" if sa.nil?

        return if sa.nil?

        sa.id
      end

      def self.get_isa_tag_id(title)
        return nil if title.blank?

        it = ISATag.find_by(title: title)
        @errors.append "<li>Could not find an ISA Tag named '#{title}'</li>" if it.nil?

        it&.id
      end

      def self.seed_isa_tags
        Rake::Task['db:seed:015_isa_tags'].invoke if ISATag.all.blank?
      end

      def self.lockfile
        Rails.root.join(Seek::Config.temporary_filestore_path, 'populate_templates.lock')
      end

      def self.resultfile
        Rails.root.join(Seek::Config.temporary_filestore_path, 'populate_templates.result')
      end
    end
  end
end
