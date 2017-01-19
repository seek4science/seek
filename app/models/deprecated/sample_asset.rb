module Deprecated
  class SampleAsset < ActiveRecord::Base
    self.table_name = 'deprecated_sample_assets'

    belongs_to :asset, polymorphic: true
    belongs_to :deprecated_sample, class_name: 'Deprecated::Sample', foreign_key: 'deprecated_sample_id'
  end
end
