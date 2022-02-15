require 'datacite/metadata'
require 'datacite/client'
require 'seek/util'

module Seek
  module Doi
    module ActsAsDoiMintable
      def self.included(mod)
        mod.extend(ClassMethods)
      end

      module ClassMethods
        # `type` can be free text, or a term from: https://dictionary.casrai.org/Output_Types
        # `general_type` should be one of the types listed in: lib/datacite/metadata.rb
        def acts_as_doi_mintable(proxy: nil, type: nil, general_type: 'Dataset')
          cattr_accessor :doi_proxy_resource, :datacite_resource_type, :datacite_resource_type_general, instance_reader: false, instance_writer: false

          self.doi_proxy_resource = proxy
          self.datacite_resource_type = type
          self.datacite_resource_type_general = general_type

          include Seek::Doi::ActsAsDoiMintable::InstanceMethods

          include Rails.application.routes.url_helpers # For URL generation
        end
      end

      module InstanceMethods
        def mint_doi
          unless doi.blank?
            errors.add(:doi, 'already minted')
            return false
          end

          unless Seek::Config.doi_minting_enabled
            errors.add(:base, 'DOI minting is not enabled')
            return false
          end

          if doi_time_locked?
            errors.add(:base, "DOIs may only be minted for resources older than #{Seek::Config.time_lock_doi_for} days.")
            return false
          end

          username = Seek::Config.datacite_username
          password = Seek::Config.datacite_password
          url = Seek::Config.datacite_url.blank? ? nil : Seek::Config.datacite_url
          endpoint = DataCite::Client.new(username, password, url)

          endpoint.upload_metadata(datacite_metadata.to_s)
          endpoint.mint(suggested_doi, doi_target_url)

          update_attribute(:doi, suggested_doi)

          create_log

          # Update the parent resource's index with the new DOI
          doi_resource.reload.index! if Seek::Config.solr_enabled && doi_resource.respond_to?(:index!)

          suggested_doi
        end

        def datacite_metadata
          DataCite::Metadata.new(
              identifier: suggested_doi,
              title: title,
              description: description,
              creators: respond_to?(:assets_creators) ? assets_creators : creators,
              year: Time.now.year.to_s,
              publisher: Seek::Config.instance_name,
              resource_type: [datacite_resource_type, datacite_resource_type_general]
          )
        end

        def datacite_resource_type
          self.class.datacite_resource_type || I18n.t(doi_resource.class.name.underscore)
        end

        def datacite_resource_type_general
          self.class.datacite_resource_type_general
        end

        def suggested_doi
          base = "#{Seek::Config.doi_prefix}/#{Seek::Config.doi_suffix}"
          resource = ".#{doi_resource_type}.#{doi_resource_id}"
          resource << ".#{doi_resource_suffix}" unless doi_resource_suffix.blank?

          base + resource
        end

        # the resolvable doi identifier URI
        def doi_identifier
          unless doi.blank?
            "https://doi.org/#{doi}"
          end
        end

        def has_doi?
          !doi.blank?
        end

        def can_mint_doi?
          Seek::Config.doi_minting_enabled && !doi_time_locked? && !has_doi?
        end

        def doi_time_locked?
          doi_time_lock_end > Time.now
        end

        def doi_time_lock_end
          (created_at + (Seek::Config.time_lock_doi_for || 0).to_i.days)
        end

        def doi_logs
          AssetDoiLog.where(asset_type: doi_resource.class.name, asset_id: doi_resource_id, asset_version: doi_resource_suffix)
        end

        private

        def doi_resource
          @doi_resource ||= (self.class.doi_proxy_resource ? send(self.class.doi_proxy_resource) : self)
        end

        def doi_target_url
          polymorphic_url(self,
                          host: Seek::Config.host_with_port,
                          protocol: Seek::Config.host_scheme)
        end

        def doi_resource_type
          doi_resource.class.name.downcase
        end

        def doi_resource_id
          doi_resource.id
        end

        def doi_resource_suffix
          version if respond_to?(:version) && !version.nil?
        end

        def create_log
          AssetDoiLog.create(asset_type: doi_resource.class.name, asset_id: doi_resource_id, asset_version: doi_resource_suffix,
                             doi: suggested_doi, action: AssetDoiLog::MINT, user_id: User.current_user.try(:id))
        end
      end
    end
  end
end
