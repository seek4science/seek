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
          unless reflect_on_association(:assays)
            has_many :assay_assets, dependent: :destroy, as: :asset, foreign_key: :asset_id, autosave: true # change this to validate: true in the future
            has_many :assays, through: :assay_assets

            def assay_assets_attributes= attributes
              self.assay_assets.reset

              new_assay_assets = []

              attributes.each do |attrs|
                existing = self.assay_assets.detect { |aa| aa.assay_id.to_s == attrs['assay_id'] }
                if existing
                  new_assay_assets << existing.tap { |e| e.assign_attributes(attrs) }
                else
                  assay = Assay.find_by_id(attrs['assay_id'])
                  if assay && assay.can_edit?
                    new_assay_assets << self.assay_assets.build(attrs)
                  end
                end
              end

              self.assay_assets = new_assay_assets
            end
          end

          unless reflect_on_association(:studies)
            def studies
              assays.map(&:study).uniq
            end
          end

          unless reflect_on_association(:investigations)
            def investigations
              studies.map(&:investigation).uniq
            end
          end
        end
      end
    end
  end
end
