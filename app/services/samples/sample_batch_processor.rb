# frozen_string_literal: true
module Samples
  class SampleBatchProcessor

    attr_reader :errors
    attr_reader :results
    def initialize(sample_type_id:, batch_process_params: [], user:, send_email: false)
      @sample_type = SampleType.find(sample_type_id)
      @projects = @sample_type.projects
      @batch_process_params = batch_process_params
      @user = user
      @send_email = send_email
      @results = []
      @errors = []

      validate!
    end

    def process!
      create_samples
      update_samples
      send_email if @send_email && Seek::Config::email_enabled && !@user.nil?
    end

    def create!
      create_samples
      send_email if @send_email && Seek::Config::email_enabled && !@user.nil?
    end

    def update!
      update_samples
      send_email if @send_email && Seek::Config::email_enabled && !@user.nil?
    end

    def delete!
      delete_samples
    end

    private

    def validate!
      raise "Missing sample_type_id or sample type not found" if @sample_type.nil?
      raise "No projects associated with this Sample Type" if @projects.empty?
      raise "Missing new_sample_params" if @batch_process_params.nil?
      raise "Missing user" if @user.nil?
    end

    def create_samples
      User.with_current_user(@user) do
        Sample.transaction do
          @batch_process_params.each do |par|
            ex_id = par.delete(:ex_id)
            sample = Sample.new(sample_type: @sample_type, policy: @sample_type.policy, projects: @projects)
            sample.assign_attributes(par)
            if sample.save
              result = { ex_id: ex_id, message: "Sample '#{sample.title}' successfully created." }
              @results << result
              Rails.logger.info result
            else
              error = { ex_id: ex_id, message: "Sample '#{sample.title}' could not be created. Please correct these errors:\n#{sample.errors.full_messages.to_sentence}." }
              @errors << error
              Rails.logger.info error
              raise ActiveRecord::Rollback
            end
          end
        end
      end
    end

    def update_samples
      User.with_current_user(@user) do
        Sample.transaction do
          @batch_process_params.each do |par|
            ex_id = par.delete(:ex_id)
            sample_id = par[:id]
            sample = Sample.find(sample_id)

            if sample.nil?
              @errors << { ex_id: ex_id, message: "Sample with id '#{sample_id}' not found." }
              next
            end

            unless sample.can_edit?(@user)
              @errors << { ex_id: ex_id, message: "Not permitted to update this sample." }
              next
            end

            sample.assign_attributes(par)
            if sample.save
              result = { ex_id: ex_id, message: "Sample '[ID: #{sample.id}] #{sample.title}' successfully updated." }
              @results << result
              Rails.logger.info result
            else
              error = { ex_id: ex_id, message: "Sample '[ID: #{sample.id}] #{sample.title}' could not be updated. Please correct these errors:\n#{sample.errors.full_messages.to_sentence}." }
              @errors << error
              Rails.logger.info error
              raise ActiveRecord::Rollback
            end
          end
        end
      end
    end

    def delete_samples
      User.with_current_user(@user) do
        Sample.transaction do
          @batch_process_params.each do |par|
            ex_id = par.delete(:ex_id)
            sample_id = par[:id]
            sample = Sample.find(sample_id)

            if sample.nil?
              @errors << { ex_id: ex_id, message: "Sample with id '#{sample_id}' not found." }
              next
            end

            unless sample.can_delete?
              @errors << { ex_id: ex_id, message: "Not permitted to delete this sample." }
              next
            end

            if sample.destroy
              @results << { ex_id: ex_id, message: "Sample '[ID: #{sample.id}] #{sample.title}' successfully deleted." }
            else
              error = { ex_id: ex_id, error: sample.errors.full_messages.to_sentence }
              @errors << error
              Rails.logger.info error
              raise ActiveRecord::Rollback
            end
          end
        end
      end
    end

    def send_email
      if @sample_type.assays.empty? && @sample_type.studies.any?
        item_type = 'study'
        item_id = @sample_type.studies.first
      elsif @sample_type.assays.any? &&@sample_type.studies.empty?
        item_type = 'assay'
        item_id = @sample_type.assays.first
      else
        item_type = 'sample_type'
        item_id = @sample_type.id
      end

      Mailer.notify_user_after_spreadsheet_extraction(@user, @projects, item_type, item_id, results, errors).deliver_now
    end
  end
end
