module Seek
  module OrcidSupport
    extend ActiveSupport::Concern

    included do
      # Validate orcid is present only on create, and only if config says so
      validates :orcid, presence: true, on: :create, if: proc { |person| person.needs_orcid? }
      # If the orcid is there, validate its format
      validates :orcid, orcid: true, allow_blank: true
      # Store in full "http://orcid.org/..." format
      before_save :format_orcid
    end

    # uri should always be https (changed from earlier guideline that http should be used)
    def orcid_uri
      return if orcid.blank?
      uri = orcid.gsub(%r{http(s)?\:\/\/orcid.org\/}, '')
      "https://orcid.org/#{uri}"
    end

    # guidelines recommend that the id should be displayed together with the https protocol
    def orcid_display_format
      return if orcid.blank?
      orcid_uri
    end

    def needs_orcid?
      Seek::Config.orcid_required &&
        !(Person.can_create? && !(User.logged_in? && !User.current_user.registration_complete?))
    end

    private

    def format_orcid
      self.orcid = orcid_uri
    end
  end
end
