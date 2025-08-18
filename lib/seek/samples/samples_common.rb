# frozen_string_literal: true
module Seek
  module Samples

    module SamplesCommon
      def batch_create_samples(params, user)
        errors = []
        results = []
        param_converter = Seek::Api::ParameterConverter.new("samples")
        User.with_current_user(user) do
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
        end
        { results: results, errors: errors }
      end

      def batch_update_samples(params, user)
        errors = []
        results = []
        param_converter = Seek::Api::ParameterConverter.new("samples")
        User.with_current_user(user) do
          Sample.transaction do
            params[:data].each do |par|
              begin
                converted_params = param_converter.convert(par)
                sample = Sample.find(par[:id])
                raise 'shouldn\'t get this far without editing rights' unless sample.can_edit?
                sample = update_sample_with_params(converted_params, sample)
                if sample.save
                  results.push({ ex_id: par[:ex_id], id: sample.id })
                else
                  errors.push({ ex_id: par[:ex_id], error: sample.errors.messages })
                end
              rescue StandardError => e
                errors.push({ ex_id: par[:ex_id], error: "Can not be updated.\n#{e.message}" })
              end
            end
            raise ActiveRecord::Rollback if errors.any?
          end
        end
        { results: results, errors: errors }
      end
    end
  end
end
