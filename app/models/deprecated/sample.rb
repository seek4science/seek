module Deprecated
  class Sample < ActiveRecord::Base
    self.table_name = 'deprecated_samples'

    belongs_to :deprecated_specimen, class_name: 'Deprecated::Specimen', foreign_key: 'deprecated_specimen_id'
    has_many :deprecated_treatments, class_name: 'Deprecated::Treatment', foreign_key: 'deprecated_sample_id'
    has_many :deprecated_sample_assets, class_name: 'Deprecated::SampleAsset', foreign_key: 'deprecated_sample_id'
    has_and_belongs_to_many :projects, foreign_key: 'deprecated_sample_id', join_table: 'deprecated_samples_projects'
    has_and_belongs_to_many :tissue_and_cell_types, foreign_key: 'deprecated_sample_id', join_table: 'deprecated_samples_tissue_and_cell_types'
    belongs_to :contributor, polymorphic: true
    belongs_to :policy
    belongs_to :age_at_sampling_unit, class_name: 'Unit'

    # This adds extra fields to the generated YAML when #to_yaml is called
    def encode_with(coder)
      h = super(coder)
      h['deprecated_treatments'] = deprecated_treatments
      h['project_ids'] = project_ids
      h['tissue_and_cell_type_ids'] = tissue_and_cell_type_ids
      h['deprecated_sample_assets'] = deprecated_sample_assets.map { |a| { id: a.id, version: a.version, type: a.asset_type }.stringify_keys }
      h
    end
  end
end
