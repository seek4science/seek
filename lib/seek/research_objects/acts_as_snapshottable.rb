module Seek #:nodoc:
  module ResearchObjects
    module ActsAsSnapshottable #:nodoc:
      def self.included(mod)
        mod.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_snapshottable
          has_many :snapshots, as: :resource, foreign_key: :resource_id

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
          ro_file = Seek::ResearchObjects::Generator.new(self).generate
          snapshot = snapshots.create
          blob = ContentBlob.new(tmp_io_object: ro_file,
                                 content_type: Mime::Type.lookup_by_extension('ro').to_s,
                                 original_filename: "#{self.class.name.underscore}-#{id}-#{snapshot.snapshot_number}.ro.zip")
          blob.asset = snapshot
          blob.save
          snapshot
        end

        def snapshot(number)
          snapshots.where(snapshot_number: number).first
        end
      end
    end
  end
end
