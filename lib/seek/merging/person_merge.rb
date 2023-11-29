module Seek
  module Merging
    module PersonMerge
      def merge(other_person)
        Person.transaction do
          merge_simple_attributes(other_person)
          merge_annotations(other_person)
          # Roles have to be merged before group_memberships
          merge_associations(other_person, 'roles', %i[scope_type scope_id role_type_id], { person_id: id })
          # Merging group_memberships deals with work_groups, programmes, institutions and projects
          merge_associations(other_person, 'group_memberships', [:work_group_id], { person_id: id })
          merge_associations(other_person, 'subscriptions', [:subscribable_id], { person_id: id })
          merge_associations(other_person, 'dependent_permissions', [:policy_id], { contributor_id: id })
          merge_resources(other_person)
          merge_user(other_person)

          save!
          other_person.reload # To prevent destruction of unlinked roles
          other_person.destroy
          ActivityLog.create!(action: 'MERGE-person',
                              data: "Person with id #{other_person.id} was merged into person with id #{id}.")
        end
      end

      private

      # This attributes are directly copied from other_person if they are empty in the person to which its merging.
      # first_letter is also updated
      def simple_attributes
        %i[
          first_name
          last_name
          email
          phone
          skype_name
          web_page
          description
          avatar_id
          orcid
        ]
      end

      def merge_simple_attributes(other_person)
        simple_attributes.each do |attribute|
          send("#{attribute}=", other_person.send(attribute)) if send(attribute).nil?
        end
        update_first_letter
      end

      def annotation_types
        %w[
          expertise
          tools
        ]
      end

      def merge_annotations(other_person)
        annotation_types.each do |annotation_type|
          add_annotations(send(annotation_type) + other_person.send(annotation_type), annotation_type.singularize, self)
        end
      end

      def merge_resources(other_person)
        # Contributed
        Person::RELATED_RESOURCE_TYPES.each do |resource_type|
          other_person.send("contributed_#{resource_type.underscore.pluralize}").in_batches.update_all(contributor_id: id)
        end
        # Created
        duplicated = other_person.created_items.pluck(:id) & created_items.pluck(:id)
        AssetsCreator.where(creator_id: other_person.id, asset_id: duplicated).in_batches.destroy_all
        AssetsCreator.where(creator_id: other_person.id).in_batches.update_all(creator_id: id)
      end

      def merge_associations(other_person, assoc, duplicates_match, update_hash)
        other_items = other_person.send(assoc).pluck(*duplicates_match)
        self_items = send(assoc).pluck(*duplicates_match)
        duplicated = other_items & self_items
        duplicated = duplicated.map { |item| [item] } if duplicates_match.length == 1

        duplicated_hash = Hash[duplicates_match.zip(duplicated.transpose)]
        other_person.send(assoc).where(duplicated_hash).in_batches.destroy_all

        other_person.send(assoc).in_batches.update_all(update_hash)
      end

      def merge_user(other_person)
        return unless user && other_person.user

        merge_user_associations(other_person, 'identities',
                                %i[provider uid], { user_id: user.id })
        merge_user_associations(other_person, 'oauth_applications',
                                %i[redirect_uri scopes], { owner_id: user.id })
        merge_user_associations(other_person, 'access_tokens',
                                %i[application_id scopes], { resource_owner_id: user.id })
        merge_user_associations(other_person, 'access_grants',
                                %i[application_id redirect_uri scopes], { resource_owner_id: user.id })
      end

      def merge_user_associations(other_person, assoc, duplicates_match, update_hash)
        other_items = other_person.user.send(assoc).pluck(*duplicates_match)
        self_items = user.send(assoc).pluck(*duplicates_match)
        duplicated = other_items & self_items
        duplicated = duplicated.map { |item| [item] } if duplicates_match.length == 1

        duplicated_hash = Hash[duplicates_match.zip(duplicated.transpose)]
        other_person.user.send(assoc).where(duplicated_hash).in_batches.destroy_all

        other_person.user.send(assoc).in_batches.update_all(update_hash)
      end

    end
  end
end
