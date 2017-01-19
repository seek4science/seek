module Deprecated
  class Treatment < ActiveRecord::Base
    self.table_name = 'deprecated_treatments'

    belongs_to :deprecated_sample, class_name: 'Deprecated::Sample', foreign_key: 'deprecated_sample_id'
    belongs_to :deprecated_specimen, class_name: 'Deprecated::Specimen', foreign_key: 'deprecated_specimen_id'
  end
end
