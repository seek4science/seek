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

    #guidelines recommend that the id should be stored as a http:// link
    def orcid_uri
      unless orcid.blank?
        uri = orcid.gsub(/http(s)?\:\/\/orcid.org\//, '')
        "http://orcid.org/#{uri}"
      end
    end

    #guidelines recommend that links should use https, yet the id stored as http
    def orcid_https_uri
      unless orcid.blank?
        #orcid uri shoudl ALWAYS be http://
        orcid_uri.gsub('http','https')
      end
    end

    #guidelines recommend that the id should be displayed without the protocol, i.e 'orcid.org/xxx-xxx'
    def orcid_display_format
      unless orcid.blank?
        #orcid uri shoudl ALWAYS be http://
        orcid_uri.gsub('http://','')
      end
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
