require 'rubygems'
require 'rake'

namespace :seek do
	desc 'Fetch ontology terms from EBI API'
	task populate_templates: :environment do
		begin
			if ENV['wipe'] == 'yes'
				puts 'Wiping templates data.....'
				Template.delete_all
				TemplateAttribute.delete_all
				SampleControlledVocab.delete_all
				SampleControlledVocabTerm.delete_all
			end

			seed_isa_tags

			disable_authorization_checks do
				client = Ebi::OlsClient.new
				project = Project.find_or_create_by(title: 'Default Project')
				Dir.foreach(File.join(Rails.root, 'config/default_data/source_types/')) do |filename|
					puts filename
					next if File.extname(filename) != '.json'
					data_hash = JSON.parse(File.read(File.join(Rails.root, 'config/default_data/source_types/', filename)))
					data_hash['data'].each do |item|
						metadata = item['metadata']
						template_details = {
							title: metadata['name'],
							group: metadata['group'],
							group_order: metadata['group_order'],
							temporary_name: metadata['temporary_name'],
							template_version: metadata['template_version'],
							isa_config: metadata['isa_config'],
							isa_measurement_type: metadata['isa_measurement_type'],
							isa_technology_type: metadata['isa_technology_type'],
							isa_protocol_type: metadata['isa_protocol_type'],
							repo_schema_id: metadata['r epo_schema_id'],
							organism: metadata['organism'],
							level: metadata['level']
						}
						tempalte = Template.find_by(template_details)

						if tempalte.blank?
							tempalte = Template.create(template_details.merge({projects: [project], policy: Policy.public_policy}))
						end

						if tempalte.id.blank?
							puts 'An error occured creating a template with the followign details: ', tempalte.errors.full_messages
							puts '==================='
							puts tempalte.inspect
							break
						end

						item['data'].each_with_index do |attribute, j|
							is_ontology = !attribute['ontology'].blank?
							is_cv = !attribute['CVList'].blank?
							scv =
								SampleControlledVocab.new(
									{
										title: attribute['name'],
										source_ontology: is_ontology ? attribute['ontology']['name'] : nil,
										ols_root_term_uri: is_ontology ? attribute['ontology']['rootTermURI'] : nil,
										custom_input: true
									}
								) if is_ontology || is_cv

							attribute_description = ''

							if is_ontology
								if attribute['ontology']['rootTermURI'].present?
									begin
										terms = client.all_descendants(attribute['ontology']['name'], attribute['ontology']['rootTermURI'])
									rescue Exception => e
										scv.save(validate: false)
										next
									end
									terms.each_with_index do |term, i|
										puts "#{j}) #{i + 1} FROM #{terms.length}"
										if i.zero?
											# Skip the parent name
											des = term[:description]
											scv[:description] = des.kind_of?(Array) ? des[0] : des
										else
											if term[:label].present? && term[:iri].present?
												cvt =
													SampleControlledVocabTerm.new(
														{ label: term[:label], iri: term[:iri], parent_iri: term[:parent_iri] }
													)
												scv.sample_controlled_vocab_terms << cvt
											end
										end
									end
								end
							elsif is_cv
								#the CV terms
								if attribute['CVList'].present?
									attribute['CVList'].each do |term|
										cvt = SampleControlledVocabTerm.new({ label: term })
										scv.sample_controlled_vocab_terms << cvt
									end
								end
							end

							if is_ontology || is_cv
								p scv.errors unless scv.save(validate: false)
							end

							tempalte_attribute_details = { title: attribute['name'], template_id: tempalte.id }
							tempalte_attribute = TemplateAttribute.find_by(tempalte_attribute_details)
							if tempalte_attribute.blank?
								TemplateAttribute.create(tempalte_attribute_details.merge({
									is_title: attribute['title'] || 0,
									isa_tag_id: get_isa_tag_id(attribute['isaTag']),
									short_name: attribute['short_name'],
									required: attribute['required'],
									description: attribute['description'],
									sample_controlled_vocab_id: scv&.id,
									iri: attribute['iri'],
									sample_attribute_type_id: get_sample_attribute_type(attribute['dataType'])
								}))
							end
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

	def seed_isa_tags
		Rake::Task['db:seed:015_isa_tags'].invoke if IsaTag.all.blank?
	end
end
