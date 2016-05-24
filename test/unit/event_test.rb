require 'test_helper'

class EventTest < ActiveSupport::TestCase
  fixtures :all

  def setup
    @event = events(:event_with_no_files)
    User.current_user = @event.contributor
  end

  test "datafile association" do
    assert @event.data_files.empty?
    datafile = data_files(:picture)
    @event.data_files << datafile
    assert @event.valid?
    assert @event.save
    assert_equal 1, @event.data_files.count
  end

   test "publication association" do
    assert @event.publications.empty?
    publication = publications(:one)
    @event.publications << publication
    assert @event.valid?
    assert @event.save
    assert_equal 1, @event.publications.count
  end

  test "sort by created_at" do
    assert_equal Event.all.sort_by { |e| e.start_date.to_i * -1 }, Event.all
  end

  test "datafiles are unique" do
    assert @event.data_files.empty?
    datafile = data_files(:picture)
    @event.data_files << datafile
    assert datafile.can_view?
    assert_no_difference '@event.data_files.count' do
      @event.data_files << datafile
      @event.save!
      @event.reload
    end
  end

  test "end date after start date" do
    assert @event.start_date != nil
    @event.end_date = Time.at 0
    assert !@event.valid?
    assert !@event.save
  end

  test "end date and start date can match" do
    @event.start_date = Time.now
    @event.end_date = @event.start_date
    assert @event.valid?
    assert @event.save
  end

  test "end date optional" do
    @event.end_date = nil
    assert @event.valid?
    assert @event.save
  end

  test "start date required" do
    @event.start_date = nil
    assert !@event.valid?
    assert !@event.save
  end

  test "presentations association" do
      event = Factory :event
      assert event.presentations.empty?

      User.current_user = event.contributor
      assert_difference "event.presentations.count" do
         event.presentations << [Factory(:presentation, :policy => Factory(:public_policy))]
      end
  end
end
