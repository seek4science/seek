# frozen_string_literal: true
module Seek
  module ISATemplates
    module TemplateLevel
      ALL_LEVELS = ["study source", "study sample", "assay - material", "assay - data file"].freeze

      ALL_LEVELS.each do |level|
        TemplateLevel.const_set(level.underscore.upcase, level)
      end

      def self.valid?(lvl)
        ALL_LEVELS.include?(lvl)
      end
    end
  end
end
