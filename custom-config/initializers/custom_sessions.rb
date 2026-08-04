# Local deploy overlay: auto-create/update Person from OIDC userinfo.
# Group → Project mapping uses in-tree Seek::Omniauth::OidcGroupProjectSync.
# Session bounce / remember-me for OmniAuth is in stock SessionsController.
#
# Prefer removing this overlay once stock registration UX is acceptable.
# Enable via docker-compose.override.yml (see docker-compose.override.yml.example).
require 'active_support/concern'

module CustomSessionsPatch
  extend ActiveSupport::Concern

  included do
    def omniauth_authentication(auth)
      @identity = Identity.from_omniauth(auth)

      if @identity.user
        @user = @identity.user
        person = @user.person

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

        sync_oidc_group_projects(auth)
        check_login
      else
        if auth.provider.to_s == 'ldap'
          @user = User.find_by_login(auth.info.nickname)
          if @user
            @identity.user = @user
            @identity.save!
            sync_oidc_group_projects(auth)
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

    def create_user_from_omniauth(auth)
      @user                     = User.from_omniauth(auth)
      @user.check_email_present = false

      email  = auth.info.email.to_s.strip
      person = Person.find_or_initialize_by(email: email)

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

      sync_oidc_group_projects(auth)
      check_login
    end
  end
end

Rails.application.config.to_prepare do
  SessionsController.include(CustomSessionsPatch)
end
