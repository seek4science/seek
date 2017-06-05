require_relative 'metadata'
require_relative 'client'
require 'seek/util'

module DataCite
  module ActsAsDoiMintable

    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods

      def acts_as_doi_mintable(proxy: nil)
        cattr_accessor :doi_proxy_resource

        self.doi_proxy_resource = proxy

        include DataCite::ActsAsDoiMintable::InstanceMethods

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

        if time_locked?
          errors.add(:base, "DOIs may only be minted for resources older than #{Seek::Config.time_lock_doi_for} days.")
          return false
        end

        username = Seek::Config.datacite_username
        password = Seek::Config.datacite_password_decrypt
        url = Seek::Config.datacite_url.blank? ? nil : Seek::Config.datacite_url
        endpoint = DataCite::Client.new(username, password, url)

        endpoint.upload_metadata(datacite_metadata.to_s)
        endpoint.mint(suggested_doi, doi_target_url)

        update_attribute(:doi, suggested_doi)

        create_log

        suggested_doi
      end

      def datacite_metadata
        DataCite::Metadata.new(
          :identifier => suggested_doi,
          :title => title,
          :description => description,
          :creators => related_people,
          :year => Time.now.year.to_s,
          :publisher => Seek::Config.project_name
        )
      end

      def suggested_doi
        base = "#{Seek::Config.doi_prefix}/#{Seek::Config.doi_suffix}"
        resource = ".#{doi_resource_type}.#{doi_resource_id}"
        resource << ".#{doi_resource_suffix}" unless doi_resource_suffix.blank?

        base + resource
      end

      def has_doi?
        !doi.blank?
      end

      def can_mint_doi?
        Seek::Config.doi_minting_enabled && !time_locked?
      end

      def time_locked?
        (created_at + (Seek::Config.time_lock_doi_for || 0).to_i.days) > Time.now
      end

      def doi_logs
        AssetDoiLog.where(asset_type: doi_resource.class.name, asset_id: doi_resource_id, asset_version: doi_resource_suffix)
      end

      private

      def doi_resource
        @doi_resource ||= (self.class.doi_proxy_resource ? self.send(self.class.doi_proxy_resource) : self)
      end

      def doi_target_url
        polymorphic_url(self,
                        :host => Seek::Config.host_with_port,
                        :protocol => Seek::Config.host_scheme)
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

ActiveRecord::Base.class_eval do
  include DataCite::ActsAsDoiMintable
end
