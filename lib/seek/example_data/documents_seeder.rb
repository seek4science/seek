module Seek
  module ExampleData
    class DocumentsSeeder
      def initialize(project, guest_person, admin_person, seed_data_dir)
        @project = project
        @guest_person = guest_person
        @admin_person = admin_person
        @seed_data_dir = seed_data_dir
      end

      def seed
        document = create_document(
          'Experimental setup for the reconstituted gluconeogenic enzyme system',
          'This document describes the experimental setup and procedures used for reconstituting the gluconeogenic enzyme system from Sulfolobus solfataricus.',
          'CC-BY-SA-4.0',
          @admin_person,
          'example_document.txt',
          'text/plain'
        )

        puts 'Seeded 1 document.'

        { document: document }
      end

      def create_document(title, description, license, creator, filename, content_type)
        document = Document.new(
          title: title,
          description: description,
          license: license
        )
        document.contributor = @guest_person
        document.projects = [@project]
        document.policy = Policy.create(name: 'default policy', access_type: 1)
        document.content_blob = ContentBlob.new(
          original_filename: filename,
          content_type: content_type
        )

        disable_authorization_checks { document.save! }
        AssetsCreator.create(asset_id: document.id, creator_id: creator.id, asset_type: document.class.name)

        # Copy file
        source_path = File.join(@seed_data_dir, filename)
        destination_path = document.content_blob.filepath
        FileUtils.cp(source_path, destination_path)

        document.content_blob.original_filename = filename
        document.content_blob.content_type = content_type
        disable_authorization_checks { document.content_blob.save! }

        # Add tags
        disable_authorization_checks do
          document.annotate_with(%w[gluconeogenesis protocol thermophile], 'tag', @guest_person)
          document.save!
        end

        document
      end

    end
  end
end
