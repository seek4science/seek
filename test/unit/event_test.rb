require 'test_helper'

class EventTest < ActiveSupport::TestCase
  fixtures :all

  test "datafile association" do
    event = events(:event_with_no_files)
    assert event.data_files.empty?
    datafile = data_files(:picture)
    event.data_files << datafile
    assert event.valid?
    assert event.save
    assert_equal 1, event.data_files.count
  end

  test "sort by created_at" do
    assert_equal Event.find(:all).sort_by { |e| e.created_at.to_i * -1 }, Event.find(:all)
  end

  test "datafiles are unique" do
    event = events(:event_with_no_files)
    assert event.data_files.empty?
    datafile = data_files(:picture)
    event.data_files << datafile
    event.data_files << datafile
    assert !event.valid?
    assert !event.save
  end

  test "end date after start date" do
    event = events(:event_with_no_files)
    assert event.start_date != nil
    event.end_date = Time.at 0
    assert !event.valid?
    assert !event.save
  end

  test "end date required" do
    event = events(:event_with_no_files)
    event.end_date = nil
    assert !event.valid?
    assert !event.save
  end

  test "start date required" do
    event = events(:event_with_no_files)
    event.start_date = nil
    assert !event.valid?
    assert !event.save
  end
end
