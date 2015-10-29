module Seek
  module OrcidSupport
    extend ActiveSupport::Concern

    included do
      # Validate orcid is present only on create, and only if config says so
      validates :orcid, presence: true, on: :create, if: Proc.new { Seek::Config.orcid_required }
      # If the orcid is there, validate its format
      validates :orcid, orcid: true, allow_blank: true
      # Store in full "http://orcid.org/..." format
      before_save :format_orcid
    end

    def orcid_uri
      unless orcid.blank?
        uri = orcid
        uri = "http://orcid.org/#{uri}" unless uri.start_with?('http://orcid.org/')
        uri
      end
    end

    private

    def format_orcid
      self.orcid = orcid_uri
    end
  end
end
