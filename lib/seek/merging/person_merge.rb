module Seek
  module Merging
    module PersonMerge
      def merge(other_person)
        merge_simple_attributes(other_person)
      end

      private

      # This attributes are directly copied from other_person if they are empty in the person to which its merging.
      # first_letter is also updated
      def simple_attributes
        %i[
          first_name
          last_name
          email
          phone
          skype_name
          web_page
          description
          avatar_id
          orcid
        ]
      end

      def merge_simple_attributes(other_person)
        simple_attributes.each do |attribute|
          send("#{attribute}=", other_person.send(attribute)) if send(attribute).nil?
        end
        update_first_letter
      end

    end
  end
end
