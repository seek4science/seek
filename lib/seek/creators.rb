module Seek
  module Creators
    extend ActiveSupport::Concern
    included do
      has_many :assets_creators, dependent: :destroy, as: :asset, foreign_key: :asset_id

      accepts_nested_attributes_for :assets_creators, allow_destroy: true

      has_many :creators, class_name: 'Person', through: :assets_creators,
               after_remove: %i[update_timestamp record_creators_changed],
               after_add: %i[update_timestamp record_creators_changed]

      has_filter :creator
    end

    def record_creators_changed(_assets_creator)
      @creators_changed = true
    end

    def creators_changed?
      @creators_changed
    end

    # API-friendly way of setting creators without doing it in the `accepts_nested_attributes_for`-way.
    # Replaces all AssetsCreators with the given set, creating, updating and deleting records as necessary.
    # It identifiers existing assets_creators by: creator_id, orcid, or identical name + affiliation.
    def api_assets_creators= attrs
      existing = assets_creators.to_a
      retained_and_new = attrs.map do |attr|
        ex = existing.detect do |ac|
          attr[:creator_id].present? && (ac.creator_id == attr[:creator_id]) ||
            attr[:orcid].present? && ac.orcid == attr[:orcid] ||
            (ac.given_name == attr[:given_name] &&
              ac.family_name == attr[:family_name] &&
              ac.affiliation == attr[:affiliation])
        end
        if ex
          ex.assign_attributes(attr)
          ex
        else
          assets_creators.build(attr)
        end
      end.compact

      (existing - retained_and_new).each(&:destroy)

      retained_and_new
    end
  end
end