# FIXME: need to check if the methods in this module are still used after moving the simulation buttons to each file of the model
module Seek
  module Models
    module ModelTypeHandling
      def contains_xgmml?(model = self)
        !model.content_blobs.detect(&:is_xgmml?).nil?
      end

      def xgmml_content_blobs(model = self)
        model.content_blobs.select(&:is_xgmml?)
      end

      def contains_jws_dat?(model = self)
        !model.content_blobs.detect(&:is_jws_dat?).nil?
      end

      def jws_dat_content_blobs(model = self)
        model.content_blobs.select(&:is_jws_dat?)
      end

      def contains_sbml?(model = self)
        !model.content_blobs.detect(&:is_sbml?).nil?
      end

      def sbml_content_blobs(model = self)
        model.content_blobs.select(&:is_sbml?)
      end

      def jws_supported_content_blobs(model = self)
        model.content_blobs.select { |cb| cb.is_jws_dat? || cb.is_sbml? }
      end

      def is_jws_supported?(model = self)
        !model.content_blobs.detect { |cb| cb.is_jws_dat? || cb.is_sbml? }.nil?
      end
    end
  end
end
