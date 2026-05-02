module Seek
  module Doi
    module ActsAsDoiParent
      def self.included(mod)
        mod.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_doi_parent(child_accessor: :versions)
          cattr_accessor :doi_child_accessor

          self.doi_child_accessor = child_accessor

          class_eval do
            def self.supports_doi?
              true
            end
          end

          searchable(auto_index: false) do
            text :doi do
              dois
            end
          end if Seek::Config.solr_enabled

          include Seek::Doi::ActsAsDoiParent::InstanceMethods
        end
      end

      module InstanceMethods
        def latest_citable_doi
          latest_citable_resource.try(:doi)
        end

        def latest_citable_resource
          doi_children.where('doi IS NOT NULL').last
        end

        def has_doi?
          latest_citable_resource.present?
        end

        def can_retract_doi?
          latest_citable_resource.can_retract_doi? if has_doi?
        end

        def retract_dois(retraction_reason = nil)
          doi_children.select(&:has_doi?).all? { |child| child.inactivate_doi(retraction_reason) }
        end

        def dois
          doi_children.map(&:doi).compact
        end

        def doi_identifiers
          doi_children.map(&:doi_identifier).compact
        end

        def state_allows_delete?(*args)
          allows_delete_after_retract = AssetDoiLog.where(asset_type: self.class.name, asset_id: id, action: AssetDoiLog::DELETE).exists?
          (allows_delete_after_retract || !has_doi?) && super(*args)
        end

        private

        def doi_children
          self.send(self.class.doi_child_accessor)
        end
      end
    end
  end
end
