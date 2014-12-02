module Seek
  module ActsAsAsset
    # Acts as Asset behaviour that relates to DOI's
    module Dois
      module InstanceMethods
        # TODO
        # is_published && can_manage
        # after one week asset is created
        # asset type
        # is_doi_already minted
        def is_doiable?(version)
          Seek::Config.doi_minting_enabled && Seek::Util.doiable_asset_types.include?(self.class) && self.can_manage? && self.is_published? && !is_doi_minted?(version) && !is_doi_locked?(version)
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
          Time.now - created_at > Seek::Config.lock_doi_after.to_i.days
        end

        def state_allows_delete?(*args)
          if Seek::Util.doiable_asset_types.include?(self.class)
            !self.is_any_doi_minted? && super
          else
            super
          end
        end
      end
    end
  end
end
