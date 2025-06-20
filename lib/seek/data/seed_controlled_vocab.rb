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
          SampleControlledVocab.transaction do
            vocab.update_from_json_dump(data, true)
            if vocab.valid?
              vocab.save
            else
              puts "validation failed: #{vocab.errors.full_messages.join(', ')}"
              bad_terms = vocab.sample_controlled_vocab_terms.reject(&:valid?)
              if bad_terms.any?
                puts "invalid terms #{bad_terms.map(&:label).join(', ')}"
              end
              raise ActiveRecord::Rollback
            end
          end
        end
      end

      def self.show_changes_summary(data, vocab, show_detailed_changes = false)
        new, removed, updated = determine_changes(data, vocab)

        puts "#{new.count} new #{'term'.pluralize(new.count)}#{':' if show_detailed_changes}" if new.any?
        if show_detailed_changes
          new.each do |term_attr|
            puts format("\t%-50s%-40s", term_attr[:label], term_attr[:iri])
          end
        end

        if updated.any?
          puts "#{updated.count} #{'term'.pluralize(updated.count)} updated#{':' if show_detailed_changes}"
        end
        if show_detailed_changes
          updated.each do |term_attr, original|
            puts format("\t%-50s%-40s%-40s", term_attr[:label], term_attr[:iri], term_attr[:parent_iri])
            puts format("WAS:\t%-50s%-40s%-40s", original.label, original.iri, original.parent_iri)
            puts
          end
        end

        if removed.any?
          puts "#{removed.count} #{'term'.pluralize(removed.count)} removed#{':' if show_detailed_changes}"
        end
        return unless show_detailed_changes

        removed.each do |term|
          puts format("\t%-50s%-40s", term.label, term.iri)
        end
      end

      def self.read_data(input, property)
        if input.is_a?(String)
          json = File.read(File.join(Rails.root, 'config/default_data/controlled-vocabs', input))
          data = JSON.parse(json).with_indifferent_access
        else
          data = input
        end
        data[:key] = SampleControlledVocab::SystemVocabs.database_key_for_property(property)
        data
      end

      def self.determine_changes(data, vocab)
        updated = []
        new = []
        removed = []
        json_terms_attributes = data[:sample_controlled_vocab_terms_attributes]
        json_terms_attributes.each do |term_attrs|
          query = vocab.sample_controlled_vocab_terms.where(iri: term_attrs[:iri]).or(vocab.sample_controlled_vocab_terms.where(label: term_attrs[:label]))
          match = query.first
          if match
            if match.label != term_attrs[:label] || match.iri != term_attrs[:iri] || match.parent_iri != term_attrs[:parent_iri]
              updated << [term_attrs, match]
            end
          else
            new << term_attrs
          end
        end
        vocab.sample_controlled_vocab_terms.each do |term|
          unless json_terms_attributes.detect { |attr| attr[:iri] == term.iri || attr[:label] == term.label }
            removed << term
          end
        end
        [new, removed, updated]
      end
    end
  end
end
