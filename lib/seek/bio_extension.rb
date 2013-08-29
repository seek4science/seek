#reformat the authors
module Seek
  module BioExtension
    class Bio::MEDLINE
      def reference_with_additional_fields
        reference = reference_without_additional_fields
        reference.published_date = published_date
        reference.error = error
        reference
      end

      alias_method_chain :reference, :additional_fields

      def published_date
        history_status_date = @pubmed['PHST']
        unless history_status_date.blank?
          #Publication History Status Date: 2012/07/19 [received] 2013/03/05 [accepted] 2013/03/16 [aheadofprint]
          if history_status_date.include?('[aheadofprint]')
            published_date_index = history_status_date.index('[aheadofprint]') - 11
            history_status_date[published_date_index, 10]
          else
            nil
          end
        else
          nil
        end
      end

      def error
         nil
      end
    end

    class Bio::Reference
      def authors_with_reformat
        authors_array = authors_without_reformat
        reformat_authors = []
        authors_array.each do |author|
          #Petzold, A.
          last_name, first_name = author.split(',')
          last_name.strip!
          first_name.strip!
          reformat_authors << Author.new(first_name, last_name)
        end
        reformat_authors
      end
      alias_method_chain :authors, :reformat

      attr_accessor :published_date, :error
    end

    class Author
      attr_accessor :first_name, :last_name

      def initialize(first, last)
        self.first_name = first
        self.last_name = last
      end

      def name
        return self.first_name + " " + self.last_name
      end
    end

  end
end
