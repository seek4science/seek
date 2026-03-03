# Custom initializer: OIDC session handling for SEEK
# - Auto-creates/updates a Person profile from OIDC userinfo on first login
# - Syncs Person details (name, email) on every subsequent login
# - For each value in the configured OIDC groups claim:
#     * Finds or creates a matching Project
#     * Adds the authenticated user as a member (or project admin if the value
#       matches an admin keyword)
require 'active_support/concern'

module CustomSessionsPatch
  extend ActiveSupport::Concern

  included do
    # ------------------------------------------------------------------
    # Called on every OIDC login – handles both existing and new users.
    # ------------------------------------------------------------------
    def omniauth_authentication(auth)
      raw_info = auth.extra&.raw_info&.to_h || {}
      Rails.logger.info "OIDC Debug: provider=#{auth.provider} uid=#{auth.uid}"
      Rails.logger.info "OIDC Debug: info keys = #{auth.info.to_h.keys.inspect}"
      raw_info.each do |key, val|
        Rails.logger.info "OIDC Debug: raw_info[#{key.inspect}] = #{val.inspect}"
      end

      @identity = Identity.from_omniauth(auth)

      if @identity.user
        # ---- Existing identity: sync profile details then log in ----
        @user   = @identity.user
        person  = @user.person

        if person
          changed = false
          %i[first_name last_name email].each do |field|
            value = auth.info.send(field).presence
            next unless value && person.send(field) != value
            person.send(:"#{field}=", value)
            changed = true
          end
          disable_authorization_checks { person.save } if changed
        end

        # Apply group → project mapping on every login so membership stays in sync
        assign_oidc_projects(auth, @user) if @user.person

        check_login
      else
        # ---- No existing identity ----
        if auth.provider.to_s == 'ldap'
          @user = User.find_by_login(auth.info.nickname)
          if @user
            @identity.user = @user
            @identity.save!
            check_login
            return
          end
        end

        if logged_in?
          link_identity_to_user(auth)
        elsif Seek::Config.omniauth_user_create
          create_user_from_omniauth(auth)
        else
          failed_login "The authenticated user: #{auth.info.nickname} does not have a #{Seek::Config.instance_name} account."
        end
      end
    end

    # ------------------------------------------------------------------
    # Called when no existing User record matches the OIDC identity.
    # Creates a User + Person from the OIDC userinfo automatically so the
    # registration page is never shown.
    # ------------------------------------------------------------------
    def create_user_from_omniauth(auth)
      @user                     = User.from_omniauth(auth)
      @user.check_email_present = false

      email  = auth.info.email.to_s.strip
      person = Person.find_or_initialize_by(email: email)

      # Populate name fields from OIDC userinfo
      if auth.info.first_name.present?
        person.first_name = auth.info.first_name
        person.last_name  = auth.info.last_name.to_s
      elsif auth.info.name.present?
        parts             = auth.info.name.split(' ', 2)
        person.first_name = parts[0]
        person.last_name  = parts[1].to_s
      end
      person.email = email

      saved = nil
      disable_authorization_checks do
        if person.save
          @user.person = person
          saved        = @user.save
        else
          Rails.logger.error "OIDC Login: Person save failed – #{person.errors.full_messages.join(', ')}"
        end
      end

      unless saved
        failed_login "Cannot create a new user: #{@user.errors.full_messages.join(', ')}."
        return
      end

      @user.activate if Seek::Config.omniauth_user_activate && !@user.active?
      @identity.user = @user
      @identity.save!

      Rails.logger.info "OIDC Login: Created user #{@user.id} / person #{person.id} for #{email}"

      assign_oidc_projects(auth, @user)

      check_login
    end

    private

    # ------------------------------------------------------------------
    # Resolves the OIDC groups claim and ensures the person is a member
    # of the corresponding Project(s).
    # ------------------------------------------------------------------
    def assign_oidc_projects(auth, user)
      person = user.person
      return unless person

      # Supports dot-notation for nested claims, e.g. "realm_access.roles" (Keycloak default)
      claim_key = ENV.fetch('OMNIAUTH_OIDC_GROUPS', ENV.fetch('OMNIAUTH_OIDC_ROLES', 'realm_access.roles'))
      raw_info  = auth.extra&.raw_info&.to_h || {}

      raw = claim_key.split('.').reduce(raw_info) do |obj, key|
        case obj
        when Hash           then obj[key]
        when nil            then nil
        else                     obj.respond_to?(key) ? obj.send(key) : nil
        end
      end
      raw ||= auth.info.try(:[], claim_key)

      groups = case raw
               when Array  then raw
               when String then raw.split(/[,;\s]+/)
               when nil    then []
               else             [raw.to_s]
               end
      groups = groups.map(&:to_s).reject(&:blank?)

      if groups.empty?
        Rails.logger.info "OIDC Login: No values in claim '#{claim_key}' – skipping project mapping"
        return
      end

      institution = default_oidc_institution
      unless institution
        Rails.logger.error "OIDC Login: Default institution unavailable – skipping project mapping"
        return
      end

      admin_keywords = ENV.fetch('OMNIAUTH_OIDC_ADMIN_KEYWORDS', 'admin,administrator,owner,admins,owners')
                          .split(/[,;\s]+/)
                          .map { |k| Regexp.new(Regexp.escape(k), Regexp::IGNORECASE) }

      groups.each do |group|
        project_title = group.split(%r{[:/\#@]}).last.to_s.strip
        project_title = group.strip if project_title.blank?

        disable_authorization_checks do
          project = Project.find_or_create_by(title: project_title) do |p|
            p.description = "Auto-created from OIDC group: #{group}"
          end

          # Ensure membership before any role assignment
          unless person.member_of?(project)
            person.add_to_project_and_institution(project, institution)
            person.save!
            Rails.logger.info "OIDC Login: Added person #{person.id} to project '#{project_title}'"
          end

          # Promote to project admin if the group name matches an admin keyword
          if admin_keywords.any? { |pat| group =~ pat }
            unless project.project_administrators.include?(person)
              project.project_administrators << person
              project.save!
              Rails.logger.info "OIDC Login: Promoted person #{person.id} to admin of '#{project_title}'"
            end
          end
        end
      end
    end

    # ------------------------------------------------------------------
    # Returns (or lazily creates) the default Institution used for OIDC
    # membership assignments.
    # ------------------------------------------------------------------
    def default_oidc_institution
      title   = ENV.fetch('OMNIAUTH_OIDC_DEFAULT_INSTITUTION', 'Default Institution')
      country = ENV.fetch('OMNIAUTH_OIDC_DEFAULT_INSTITUTION_COUNTRY', 'GB')
      city    = ENV.fetch('OMNIAUTH_OIDC_DEFAULT_INSTITUTION_CITY', '')
      web     = ENV.fetch('OMNIAUTH_OIDC_DEFAULT_INSTITUTION_WEB', '')

      disable_authorization_checks do
        Institution.find_or_create_by(title: title) do |inst|
          inst.country  = country
          inst.city     = city
          inst.web_page = web.presence
        end
      end
    rescue => e
      Rails.logger.error "OIDC Login: Institution lookup/create failed – #{e.message}"
      nil
    end
  end
end

Rails.application.config.to_prepare do
  SessionsController.include(CustomSessionsPatch)
end
