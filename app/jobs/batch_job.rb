# An abstract job for dealing with batches of items.
class BatchJob < ApplicationJob
  def perform
    gather_items.each do |item|
      begin
        perform_job(item)
      rescue Exception => exception
        raise exception if Rails.env.test?
        unless item.respond_to?(:destroyed?) && item.destroyed?
          self.class.report_exception(exception, nil, { item: item })
        end
      end
    end
  end

  private

  def gather_items
    []
  end
end
