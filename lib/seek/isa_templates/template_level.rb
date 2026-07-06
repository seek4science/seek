# frozen_string_literal: true
module Seek
  module ISATemplates
    module TemplateLevel

      STUDY_SOURCE = "study source"
      STUDY_SAMPLE = "study sample"
      ASSAY_MATERIAL = "assay - material"
      ASSAY_DATA_FILE = "assay - data file"

      ALL_LEVELS = [STUDY_SOURCE, STUDY_SAMPLE, ASSAY_MATERIAL, ASSAY_DATA_FILE].freeze

      def self.valid?(lvl)
        ALL_LEVELS.include?(lvl)
      end
    end
  end
end
