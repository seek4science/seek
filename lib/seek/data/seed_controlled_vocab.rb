module Seek
  module Data
    class SeedControlledVocab
      def self.seed(json_file, property)
        data = read_data(json_file, property)
        name = property.to_s.humanize

        if (vocab = SampleControlledVocab::SystemVocabs.vocab_for_property(property))
          update_existing(data, name, vocab)
        else
          create_new(data, name)
        end
        puts '... Done'
      end

      def self.create_new(data, name)
        puts "Seeding #{name} controlled vocabulary ..."

        vocab = SampleControlledVocab.new(data)

        disable_authorization_checks do
          vocab.save!
        end
      end

      def self.update_existing(data, name, vocab)
        puts "#{name} controlled vocabulary already exists, updating ..."
        show_changes_summary(data, vocab)

        disable_authorization_checks do
          # vocab.update_from_json_dump(data)
          # vocab.save!
        end
      end

      def self.show_changes_summary(data, vocab)
        current_iris = vocab.sample_controlled_vocab_terms.collect(&:iri)
        terms = data[:sample_controlled_vocab_terms_attributes]
        update_iris = terms.collect { |atr| atr[:iri] }
        gone = current_iris - update_iris
        new = update_iris - current_iris
        puts "#{new.count} new #{'term'.pluralize(new.count)}#{':' if new.any?}"
        new.each do |iri|
          term = terms.detect { |t| iri == t[:iri] }
          puts "\t#{term[:label]}\t#{iri}"
        end
        puts "#{gone.count} #{'term'.pluralize(gone.count)} removed#{':' if gone.any?}"
        gone.each do |iri|
          term = vocab.sample_controlled_vocab_terms.where(iri: iri).first
          puts "\t#{term.label}\t#{iri}"
        end
      end

      def self.read_data(json_file, property)
        json = File.read(File.join(Rails.root, 'config/default_data', json_file))
        data = JSON.parse(json).with_indifferent_access
        data[:key] = SampleControlledVocab::SystemVocabs.database_key_for_property(property)
        data
      end
    end
  end
end
