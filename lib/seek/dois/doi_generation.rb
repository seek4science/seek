module Seek
  module Dois
    module DoiGeneration
      extend ActiveSupport::Concern

      included do
        def self.supports_doi?
          true
        end
      end

      # TODO
      # is_published && can_manage
      # after one week asset is created
      # asset type
      # is_doi_already minted
      def is_doiable?(version)
        self.supports_doi? && Seek::Config.doi_minting_enabled && self.can_manage? && self.is_published? && !is_doi_minted?(version) && !is_doi_locked?(version)
      end

      def is_doi_minted?(version)
        asset_version = find_version version
        !asset_version.doi.blank?
      end

      def is_any_doi_minted?
        !versions.map(&:doi).compact.empty?
      end

      # minting doi is locked after configuration days since the asset version is created
      def is_doi_locked?(version)
        asset_version = find_version version
        created_at = asset_version.created_at
        lock_doi_after = Seek::Config.lock_doi_after
        if lock_doi_after.nil?
          false
        else
          Time.now - created_at > lock_doi_after.to_i.days
        end
      end

      def state_allows_delete?(*args)
        if self.supports_doi?
          !self.is_any_doi_minted? && super
        else
          super
        end
      end

    end
  end
end

ActiveRecord::Base.class_eval do
  def self.supports_doi?
    false
  end

  def supports_doi?
    self.class.supports_doi?
  end
end
