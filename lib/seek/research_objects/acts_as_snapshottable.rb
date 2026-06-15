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
        def create_snapshot(snapshot_metadata = {})
          Rails.logger.debug("Creating snapshot for: #{self.class.name} #{id}")
          snapshot = snapshots.build(snapshot_metadata)
          return snapshot unless snapshot.save
          filename = "#{self.class.name.underscore}-#{id}-#{snapshot.snapshot_number}.ro.zip"
          blob = snapshot.build_content_blob(content_type: Mime::Type.lookup_by_extension('ro').to_s,
                                             original_filename: filename)
          ro_file = nil
          fixed_file = nil
          begin
            Rails.logger.debug("Generating RO...")
            ro_file = Seek::ResearchObjects::Generator.new(self).generate
            Rails.logger.debug("Writing zip file to content blob (and fixing)...")
            # Repair the zip into a tempfile, then store it through the storage adapter
            # (local or S3) rather than writing directly to a local filepath. Array form
            # of zip avoids shell interpolation of the path.
            fixed_file = Tempfile.new(['snapshot', '.ro.zip'])
            fixed_file.close
            system('zip', '-FF', ro_file.path, '--out', fixed_file.path)
            blob.tmp_io_object = File.open(fixed_file.path)
            blob.save!
            Rails.logger.debug("Done!")
            snapshot
          rescue StandardError => e
            # Clean up
            snapshot.destroy
            blob.destroy if blob.persisted? # adapter delete handles the stored object
            raise e
          ensure
            if ro_file
              ro_file.close unless ro_file.closed?
              File.delete(ro_file.path) if File.exist?(ro_file.path)
            end
            File.delete(fixed_file.path) if fixed_file && File.exist?(fixed_file.path)
          end
        end

        def snapshot(number)
          snapshots.where(snapshot_number: number).first
        end
      end
    end
  end
end
