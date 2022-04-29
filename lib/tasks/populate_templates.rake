require 'rubygems'
require 'rake'


namespace :seek do
  desc "Fetch ontology terms from EBI API"
  task :populate_templates => :environment do
    begin
      if ENV['wipe'] == "yes"
        puts "Wiping templates data....."
        Template.delete_all
        TemplateAttribute.delete_all
        SampleControlledVocab.delete_all
        SampleControlledVocabTerm.delete_all
      end

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
            repo_schema_id: metadata["r epo_schema_id"], 
            organism: metadata["organism"], 
            level: metadata["level"],
            projects:[project],
            policy: Policy.public_policy
            })

						if (repo.id.blank?)
							puts "An error occured creating a template with the followign details: ", repo.errors.full_messages
							puts "==================="
							puts repo.inspect
							return
						end
  
            item["data"].each_with_index do |attribute, j|
              is_ontology = !attribute["ontology"].blank?
              is_CV = !attribute["CVList"].blank?
              scv = SampleControlledVocab.new({
                title: attribute["name"],
                source_ontology: is_ontology ? attribute["ontology"]["name"] : nil,
                ols_root_term_uri: is_ontology ? attribute["ontology"]["rootTermURI"] : nil
              }) if is_ontology || is_CV
              
              attribute_description=''

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
                    if i==0 # Skip the parent name
                      des = term[:description]
                      scv[:description] = des.kind_of?(Array) ? des[0] : des
                    else
                      if (!term[:label].blank? && !term[:iri].blank?) 
                        cvt = SampleControlledVocabTerm.new({ label: term[:label], iri: term[:iri], parent_iri: term[:parent_iri] })
                        scv.sample_controlled_vocab_terms << cvt
                      end
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
                is_title: attribute["title"]||0, 
                isa_tag_id: get_isa_tag_id(attribute["isaTag"]),
                short_name: attribute["short_name"],
                required: attribute["required"],
                description: attribute["description"],
                sample_controlled_vocab_id: scv.blank? ? nil : scv.id,
                template_id: repo.id,
                iri: attribute["iri"],
                sample_attribute_type_id: get_sample_attribute_type(attribute["dataType"]) #Based on sample_attribute_type table
              })

            end
  
          end
        end
      end
    rescue Exception => e
      puts e
    end
  end

  def get_sample_attribute_type(title)
    SampleAttributeType.where(title: title).first.id
  end

  def get_isa_tag_id(title)
    return nil if title.blank?
    IsaTag.where(title: title).first.id
  end
end