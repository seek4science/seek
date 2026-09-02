# frozen_string_literal: true

module Seek
  module Omniauth
    # Maps OIDC group/entitlement claims to SEEK Projects on login.
    #
    # Enabled via Seek::Config.omniauth_oidc_groups_enabled (default: false).
    #
    # For each group value:
    # - create the Project if missing and make the person a project administrator
    # - if the Project exists with no administrators, make the person an administrator
    # - otherwise add the person as a normal member
    #
    # Membership is additive only; leaving an IdP group does not remove SEEK membership.
    class OidcGroupProjectSync
      def self.call(person:, auth:)
        new(person: person, auth: auth).call
      end

      def initialize(person:, auth:)
        @person = person
        @auth = auth
      end

      def call
        return unless Seek::Config.omniauth_oidc_groups_enabled
        return unless @person
        return if groups.empty?

        institution = resolve_institution
        unless institution
          Rails.logger.warn('OIDC group sync: no institution configured/available – skipping')
          return
        end

        groups.each do |group|
          sync_group(group, institution)
        end
      end

      def groups
        @groups ||= normalize_groups(extract_claim(Seek::Config.omniauth_oidc_groups_claim))
      end

      def project_title_for(group)
        self.class.project_title_for(group)
      end

      def self.project_title_for(group)
        title = group.to_s.split(%r{[:/\#@]}).last.to_s.strip
        title = group.to_s.strip if title.blank?
        title
      end

      def self.extract_claim_value(raw_info, claim_path)
        return nil if claim_path.blank?

        claim_path.to_s.split('.').reduce(raw_info) do |obj, key|
          case obj
          when Hash
            obj[key] || obj[key.to_sym]
          when nil
            nil
          else
            obj.respond_to?(key) ? obj.public_send(key) : nil
          end
        end
      end

      def self.normalize_groups(raw)
        values = case raw
                 when Array then raw
                 when String then raw.split(/[,;\s]+/)
                 when nil then []
                 else [raw.to_s]
                 end
        values.map(&:to_s).map(&:strip).reject(&:blank?).uniq
      end

      private

      def extract_claim(claim_path)
        raw_info = @auth.extra&.raw_info
        raw_info = raw_info.to_h if raw_info.respond_to?(:to_h)
        raw_info ||= {}

        value = self.class.extract_claim_value(raw_info, claim_path)
        value = @auth.info[claim_path] if value.nil? && @auth.info.respond_to?(:[])
        value
      end

      def normalize_groups(raw)
        self.class.normalize_groups(raw)
      end

      def resolve_institution
        if Seek::Config.omniauth_oidc_groups_institution_id.present?
          institution = Institution.find_by(id: Seek::Config.omniauth_oidc_groups_institution_id)
          return institution if institution
        end

        @person.institutions.first || Institution.first
      end

      def sync_group(group, institution)
        title = project_title_for(group)
        return if title.blank?

        disable_authorization_checks do
          Project.transaction do
            project = Project.lock.find_by(title: title)
            created = false

            unless project
              project = Project.create!(title: title, description: "Auto-created from OIDC group: #{group}")
              created = true
            end

            ensure_membership(project, institution)

            if created || project.project_administrators.empty?
              ensure_project_administrator(project)
            end
          end
        end
      rescue StandardError => e
        Rails.logger.error("OIDC group sync failed for '#{group}': #{e.class}: #{e.message}")
        raise if Rails.env.test?
      end

      def ensure_membership(project, institution)
        @person.reload
        return if @person.member_of?(project)

        work_group = WorkGroup.find_or_create_by!(project_id: project.id, institution_id: institution.id)
        membership = GroupMembership.find_or_initialize_by(person_id: @person.id, work_group_id: work_group.id)
        membership.save! if membership.new_record?
        @person.reload
      end

      def ensure_project_administrator(project)
        @person.reload
        return if @person.is_project_administrator?(project)

        @person.is_project_administrator = true, project
        @person.save!
      end
    end
  end
end
