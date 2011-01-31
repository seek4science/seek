require 'test_helper'

class EventTest < ActiveSupport::TestCase
  fixtures :all
  # Replace this with your real tests.
  test "datafile association" do
    event = events(:event_with_no_files)
    assert event.data_files.empty?
    datafile = data_files(:picture)
    event.data_files << datafile
    assert event.valid?
    assert event.save
    assert_equal 1, event.data_files.count
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
end
