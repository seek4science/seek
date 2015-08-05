require_relative 'metadata'
require 'seek/util'

module DataCite
  module ActsAsDoiMintable

    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods

      def acts_as_doi_mintable
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
        # TODO: Implement me
        raise "NOT IMPLEMENTED"
        puts datacite_metadata.to_s
        puts
        puts suggested_doi
        puts
        puts doi_target_url
        puts
        if Rails.env.test?
          update_attribute(:doi, suggested_doi)
        else
          # username = Seek::Config.datacite_username
          # password = Seek::Config.datacite_password_decrypt
          # url = Seek::Config.datacite_url.blank? ? nil : Seek::Config.datacite_url
          # endpoint = Datacite.new(username, password, url)
          #
          # endpoint.upload_metadata(datacite_metadata.to_s)
          # endpoint.mint(suggested_doi, doi_target_url)
          #
          update_attribute(:doi, suggested_doi)
        end
      end

      def datacite_metadata
        DataCite::Metadata.new(
          :identifier => suggested_doi,
          :title => title,
          :description => description,
          :creators => [contributor.try(:person)],
          :year => Time.now.year.to_s,
          :publisher => Seek::Config.project_name
        )
      end

      def suggested_doi
        "#{Seek::Config.doi_prefix}/#{Seek::Config.doi_suffix}.#{doi_resource_type}.#{doi_resource_id}"
      end

      def has_doi?
        !doi.blank?
      end

      private

      def doi_target_url
        polymorphic_url(self, :host => Seek::Util.host)
      end

      def doi_resource_type
        self.class.name.downcase
      end

      def doi_resource_id
        ending = id.to_s
        if respond_to?(:version) && !version.nil?
          ending << ".#{version}"
        end
        ending
      end
    end

  end
end

ActiveRecord::Base.class_eval do
  include DataCite::ActsAsDoiMintable
end
