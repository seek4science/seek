# frozen_string_literal: true
module Seek
    module Samples
      include Seek::AssetsCommon

      module SamplesCommon
        def update_sample_with_params(parameters = params, sample = @sample)
          sample.assign_attributes(sample_params(sample.sample_type, parameters))
          update_sharing_policies(sample, parameters)
          update_annotations(parameters[:tag_list], sample)
          update_relationships(sample, parameters)
          sample
        end
      end
    end
end
