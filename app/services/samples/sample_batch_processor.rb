# frozen_string_literal: true
module Samples
  class SampleBatchProcessor

    attr_reader :errors
    def initialize(sample_type_id:, new_sample_params:, updated_sample_params:, user:, send_email: false)
      @sample_type = SampleType.find(sample_type_id)
      @projects = @sample_type.projects
      @new_sample_params = new_sample_params
      @updated_sample_params = updated_sample_params
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

    private

    def validate!
      raise "Missing sample_type_id or sample type not found" if @sample_type.nil?
      raise "No projects associated with this Sample Type" if @projects.empty?
      raise "Missing new_sample_params" if @new_sample_params.nil?
      raise "Missing updated_sample_params" if @updated_sample_params.nil?
      raise "Missing user" if @user.nil?
    end

    def create_samples
      User.with_current_user(@user) do
        Sample.transaction do
          @new_sample_params.each do |par|
            sample = Sample.new(sample_type: @sample_type, policy: @sample_type.policy, projects: @projects)
            sample.assign_attributes(par)
            if sample.save
              result_message = "Sample '#{sample.title}' successfully created."
              @results << result_message
              Rails.logger.info result_message
            else
              error_message = "Sample could be created. Please correct these errors:\n#{sample.errors.full_messages.to_sentence}."
              @errors << error_message
              Rails.logger.error error_message
              raise ActiveRecord::Rollback
            end
          end
        end
      end
    end

    def update_samples
      User.with_current_user(@user) do
        Sample.transaction do
          @updated_sample_params.each do |par|
            sample_id = par[:id]
            sample = Sample.find(sample_id)
            raise "Sample with id '#{sample_id}' not found." if sample.nil?
            raise "Not permitted to update sample." if sample.can_edit?(@user)
            sample.assign_attributes(par)
            if sample.save
              result_message = "Sample '[ID: #{sample.id}] #{sample.title}' successfully updated."
              @results << result_message
              Rails.logger.info result_message
            else
              error_message = "Sample could be created. Please correct these errors:\n#{sample.errors.full_messages.to_sentence}."
              @errors << error_message
              Rails.logger.error error_message
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
