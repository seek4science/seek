module Seek
  module ActsAsAsset
    # Acts as Asset behaviour that relates to the ISA framework
    module ISA
      module InstanceMethods
        def studies
          assays.map { |a| a.study }.uniq
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
