module Seek
  module ExampleData
    class CollectionsSeeder
      def initialize(project, guest_person, content_hash)
        @project = project
        @guest_person = guest_person
        @content_hash = content_hash
      end

      def seed
        collection = Collection.new(
          title: 'Gluconeogenesis in Sulfolobus solfataricus',
          description: 'A collection of data files, models, SOPs and publications related to the reconstituted gluconeogenic enzyme system from Sulfolobus solfataricus.'
        )
        collection.projects = [@project]
        collection.contributor = @guest_person
        collection.license = 'CC-BY-4.0'
        collection.policy = Policy.create(name: 'default policy', access_type: 1)

        disable_authorization_checks do
          collection.annotate_with(['gluconeogenesis', 'thermophile', 'metabolism'], 'tag', @guest_person)
          collection.save!
          @content_hash.each do |item|
            CollectionItem.create!(collection: collection, asset: item[:asset], comment: item[:comment], order: item[:order])
          end
        end

        { collection: collection }
      end
    end
  end
end
