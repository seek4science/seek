require 'rubygems'
require 'rake'


namespace :seek do
  desc "Fetch EFO ontology terms from EBI API"
  task :fetch_efo_terms => :environment do
    begin
      disable_authorization_checks do

        client = Ebi::OlsClient.new

        sources = YAML.load_file(File.join(Rails.root, 'config/default_data/source_types.yml')).values

        sources.each do |source|
          repo = RepositoryStandard.find_or_create_by({title: source['name'], group_tag: source['group'], repo_type: source['source_type']})
          attributes = source['attributes']
          attributes.each do |attribute|
            attribute.each do |property|
              required = property[1]['title'].include? "*"
              name = property[1]['title'].sub '*', ''
              iri = property[1]['IRI']
              short_name = property[1]['short_name']
              description = property[1]['description'] 
              
              scv = SampleControlledVocab.new({title: name, description: description,
              source_ontology: "Experimental Factor Ontology", ols_root_term_uri: "http://www.ebi.ac.uk/efo/EFO_0000001",
              required: required, short_name: short_name})

              scv.repository_standard = repo
              if !iri.blank?
                begin
                  terms = client.all_descendants("efo", iri)
                rescue Exception => e
                  next
                end
                terms.each_with_index do |term, i|
                  puts "#{i} FROM #{terms.length}"
                  if (!term[:label].blank? && !term[:iri].blank?)
                    cvt = SampleControlledVocabTerm.new({ label: term[:label], iri: term[:iri], parent_iri: term[:parent_iri] })
                    scv.sample_controlled_vocab_terms << cvt
                  end
                end
              end

              if !scv.save
                puts scv.errors.inspect
              end

            end
          end
        end
      end
    rescue Exception => e
      puts e
    end
  end
end