module Git
  module DoiCompatibility
    def doi_target_url
      polymorphic_url(parent, version: version,
                      host: Seek::Config.host_with_port,
                      protocol: Seek::Config.host_scheme)
    end

    def can_mint_doi?
      super && !mutable?
    end
  end
end