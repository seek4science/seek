# frozen_string_literal: true
module Seek
    module Samples

      module SamplesCommon
        def update_sample_with_params(parameters = params, sample)
          sample.assign_attributes(sample_params(sample.sample_type, parameters))
          update_sharing_policies(sample, parameters)
          update_annotations(parameters[:tag_list], sample)
          update_relationships(sample, parameters)
          sample
        end

        def batch_create_samples(params)
          errors = []
          results = []
          param_converter = Seek::Api::ParameterConverter.new("samples")
          Sample.transaction do
            params[:data].each do |par|
              converted_params = param_converter.convert(par)
              sample_type = SampleType.find_by_id(converted_params.dig(:sample, :sample_type_id))
              sample = Sample.new(sample_type: sample_type)
              sample = update_sample_with_params(converted_params, sample)
              if sample.save
                results.push({ ex_id: par[:ex_id], id: sample.id })
              else
                errors.push({ ex_id: par[:ex_id], error: sample.errors.messages })
              end
            end
            raise ActiveRecord::Rollback if errors.any?
          end
          { results: results, errors: errors }
        end
      end
    end
end
