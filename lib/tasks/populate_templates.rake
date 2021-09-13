require 'rubygems'
require 'rake'


namespace :seek do
  desc "Fetch ontology terms from EBI API"
  task :populate_templates => :environment do
    begin
      Template.delete_all
      SampleControlledVocab.delete_all
      SampleControlledVocabTerm.delete_all

      disable_authorization_checks do
        client = Ebi::OlsClient.new
        project = Project.find_or_create_by(title:'Default Project')
        Dir.foreach(File.join(Rails.root, 'config/default_data/source_types/')) do |filename|
          puts filename
          next if File.extname(filename) != '.json'
          data_hash = JSON.parse(File.read(File.join(Rails.root, 'config/default_data/source_types/', filename)))
          data_hash["data"].each do |item|
            metadata = item["metadata"]
            repo = Template.find_or_create_by({
            title: metadata["name"], 
            group: metadata["group"], 
            group_order: metadata["group_order"], 
            temporary_name: metadata["temporary_name"], 
            template_version: metadata["template_version"], 
            isa_config: metadata["isa_config"], 
            isa_measurement_type: metadata["isa_measurement_type"], 
            isa_technology_type: metadata["isa_technology_type"], 
            isa_protocol_type: metadata["isa_protocol_type"], 
            repo_schema_id: metadata["repo_schema_id"], 
            organism: metadata["organism"], 
            level: metadata["level"],
            projects:[project]})

            policy = Policy.default
            policy.save
            repo.policy_id = policy.id
            repo.update_column(:policy_id,policy.id)
  
            item["data"].each_with_index do |attribute, j|
              is_ontology = !attribute["ontology"].blank?
              is_CV = !attribute["CVList"].blank?
              scv = SampleControlledVocab.new({
                title: attribute["name"],
                source_ontology: is_ontology ? attribute["ontology"]["name"] : nil,
                ols_root_term_uri: is_ontology ? attribute["ontology"]["rootTermURI"] : nil
              }) if is_ontology || is_CV
              
              if is_ontology
                if !attribute["ontology"]["rootTermURI"].blank?
                  begin
                    terms = client.all_descendants(attribute["ontology"]["name"], attribute["ontology"]["rootTermURI"])
                  rescue Exception => e
                    scv.save(validate: false)
                    next
                  end
                  terms.each_with_index do |term, i|
                    puts "#{j}) #{i+1} FROM #{terms.length}"
                    if (!term[:label].blank? && !term[:iri].blank?)
                      cvt = SampleControlledVocabTerm.new({ label: term[:label], iri: term[:iri], parent_iri: term[:parent_iri] })
                      scv.sample_controlled_vocab_terms << cvt
                    end
                  end
                end
              elsif is_CV #the CV terms
                if !attribute["CVList"].blank?
                  attribute["CVList"].each do |term|
                    cvt = SampleControlledVocabTerm.new({ label: term })
                    scv.sample_controlled_vocab_terms << cvt
                  end
                end
              end
  
              if is_ontology || is_CV
                if !scv.save(validate: false)
                  puts scv.errors.inspect
                end
              end
              
              TemplateAttribute.create({
                title: attribute["name"], 
                short_name: attribute["short_name"],
                required: attribute["required"],
                description: attribute["description"],
                sample_controlled_vocab_id: scv.blank? ? nil : scv.id,
                template_id: repo.id,
                sample_attribute_type_id: is_ontology ? 23 : is_CV ? 18 : 7 #Based on sample_attribute_type table
              })

            end
  
          end
        end
      end
    rescue Exception => e
      puts e
    end
  end
end