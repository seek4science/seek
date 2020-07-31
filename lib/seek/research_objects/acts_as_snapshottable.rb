module Seek #:nodoc:
  module ResearchObjects
    module ActsAsSnapshottable #:nodoc:
      def self.included(mod)
        mod.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_snapshottable
          has_many :snapshots, as: :resource, foreign_key: :resource_id, dependent: :destroy

          # Index DOIs from snapshots in Solr
          searchable(auto_index: false) do
            text :doi do
              snapshots.map(&:doi).compact
            end
          end if Seek::Config.solr_enabled

          include Seek::ResearchObjects::ActsAsSnapshottable::InstanceMethods

          acts_as_doi_parent(child_accessor: :snapshots)
        end

        def is_snapshottable?
          include?(Seek::ResearchObjects::ActsAsSnapshottable::InstanceMethods)
        end
      end

      module InstanceMethods
        def create_snapshot
          Rails.logger.debug("Creating snapshot for: #{self.class.name} #{id}")
          snapshot = snapshots.create
          filename = "#{self.class.name.underscore}-#{id}-#{snapshot.snapshot_number}.ro.zip"
          blob = snapshot.build_content_blob(content_type: Mime::Type.lookup_by_extension('ro').to_s,
                                             original_filename: filename)
          ro_file = nil
          begin
            Rails.logger.debug("Generating RO...")
            ro_file = Seek::ResearchObjects::Generator.new(self).generate
            Rails.logger.debug("Writing zip file to content blob (and fixing)...")
            `zip -FF #{ro_file.path} --out #{blob.filepath}`
            blob.save!
            Rails.logger.debug("Done!")
            snapshot
          rescue StandardError => e
            # Clean up
            snapshot.destroy
            blob.destroy
            File.delete(blob.filepath) if File.exist?(blob.filepath)
            raise e
          ensure
            if ro_file
              ro_file.close unless ro_file.closed?
              File.delete(ro_file.path) if File.exist?(ro_file.path)
            end
          end
        end

        def snapshot(number)
          snapshots.where(snapshot_number: number).first
        end
      end
    end
  end
end
