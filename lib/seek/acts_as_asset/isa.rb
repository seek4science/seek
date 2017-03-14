module Seek
  module ActsAsAsset
    # Acts as Asset behaviour that relates to the ISA framework
    module ISA
      module InstanceMethods
        def related_people
          people = [contributor.try(:person)]
          people |= creators if self.respond_to?(:creators)
          people.compact.uniq
        end

        def investigations
          studies.map(&:investigation).uniq
        end

        def studies
          assays.map(&:study).uniq
        end

        def assay_type_titles
          assays.map { |at| at.try(:assay_type_label) }.compact
        end

        def technology_type_titles
          assays.map { |tt| tt.try(:technology_type_label) }.compact
        end
      end

      module Associations
        extend ActiveSupport::Concern
        included do
          has_many :assay_assets, dependent: :destroy, as: :asset, foreign_key: :asset_id
          has_many :assays, through: :assay_assets
        end
      end
    end
  end
end
