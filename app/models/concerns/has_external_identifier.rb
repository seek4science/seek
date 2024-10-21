module HasExternalIdentifier
  extend ActiveSupport::Concern

  included do

  end

  class_methods do
    def has_external_identifier
      include HasExternalIdentifier::InstanceMethods
      validate :check_external_identifier_unique_for_project

      if Seek::Config.solr_enabled
        searchable(auto_index: false) do
          text :external_identifier
        end
      end
    end

    # returns an item where :external_identifier and any of the projects match
    def by_external_identifier(external_identifier, projects)
      self.where(external_identifier: external_identifier).each do |item|
        return item if (item.projects & projects).any?
      end
      nil
    end

  end

  module InstanceMethods
    def check_external_identifier_unique_for_project
      return unless external_identifier
      matches = self.class.where(external_identifier: external_identifier).where.not(id: id)
      if matches.any?
        matches.each do |match|
          if (match.projects & projects).any?
            errors.add(:external_identifier, "is not unique within the scope of the associated #{I18n.t('project').pluralize}")
            return false
          end
        end
      end
    end
  end
end