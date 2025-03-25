module Seek
  module Data
    class SeedControlledVocab
      def self.seed(json_file, property)
        json = File.read(File.join(Rails.root, 'config/default_data', json_file))
        data = JSON.parse(json).with_indifferent_access
        data[:key] = SampleControlledVocab::SystemVocabs.database_key_for_property(property)
        name = property.to_s.humanize

        if (vocab = SampleControlledVocab::SystemVocabs.vocab_for_property(property))
          puts "#{name} controlled vocabulary already exists, updating ..."
          current_iris = vocab.sample_controlled_vocab_terms.collect(&:iri)
          update_iris = data[:sample_controlled_vocab_terms_attributes].collect { |atr| atr[:iri] }
          gone = current_iris - update_iris
          new = update_iris - current_iris
          puts "#{new.count} #{'term'.pluralize(new.count)} new terms"
          puts "#{gone.count} #{'term'.pluralize(gone.count)} terms removed: "
          gone.each do |iri|
            term = vocab.sample_controlled_vocab_terms.where(iri: iri).first
            puts "\t#{term.label}\t#{iri}"
          end

          disable_authorization_checks do
            # vocab.update_from_json_dump(data)
            # vocab.save!
          end
        else
          puts "Seeding #{name} controlled vocabulary ..."

          vocab = SampleControlledVocab.new(data)

          disable_authorization_checks do
            vocab.save!
          end

          puts '... Done'
        end
      end
    end
  end
end
