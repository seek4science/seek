require 'test_helper'

class EventTest < ActiveSupport::TestCase
  fixtures :all

  def setup
    @event = events(:event_with_no_files)
    User.current_user = @event.contributor
  end

  test 'datafile association' do
    assert @event.data_files.empty?
    datafile = data_files(:picture)
    @event.data_files << datafile
    assert @event.valid?
    assert @event.save
    assert_equal 1, @event.data_files.count
  end

  test 'publication association' do
    assert @event.publications.empty?
    publication = FactoryBot.create(:publication)
    @event.publications << publication
    assert @event.valid?
    assert @event.save
    assert_equal 1, @event.publications.count
  end

  test 'sort by created_at' do
    assert_equal Event.all.sort_by { |e| e.start_date.to_i * -1 }, Event.all
  end

  test 'datafiles are unique' do
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

  test 'end date after start date' do
    assert !@event.start_date.nil?
    @event.end_date = Time.at 0
    assert !@event.valid?
    assert !@event.save
  end

  test 'end date and start date can match' do
    @event.start_date = Time.now
    @event.end_date = @event.start_date
    assert @event.valid?
    assert @event.save
  end

  test 'end date optional' do
    @event.end_date = nil
    assert @event.valid?
    assert @event.save
  end

  test 'validates and tests url' do
    @event.url = nil
    assert @event.valid?

    @event.url = ''
    assert @event.valid?

    @event.url = 'fish'
    refute @event.valid?

    @event.url = 'http://google.com'
    assert @event.valid?

    @event.url = 'https://google.com'
    assert @event.valid?

    @event.url = '  http://google.com   '
    assert @event.valid?
    assert_equal 'http://google.com', @event.url
  end

  test 'start date required' do
    @event.start_date = nil
    assert !@event.valid?
    assert !@event.save
  end

  test 'presentations association' do
    event = FactoryBot.create :event
    assert event.presentations.empty?

    User.current_user = event.contributor
    assert_difference 'event.presentations.count' do
      event.presentations << [FactoryBot.create(:presentation, policy: FactoryBot.create(:public_policy))]
    end
  end

  test 'contributors method non non-versioned asset' do
    event = FactoryBot.create(:event)

    refute event.respond_to?(:versions)
    assert_equal 1, event.contributors.length
    assert_includes event.contributors, event.contributor
  end

  test 'link to documents' do
    person = FactoryBot.create(:person)
    User.with_current_user(person.user) do
      event = FactoryBot.create(:event, contributor:person)
      assert_empty event.documents
      doc = FactoryBot.create(:document, contributor:person)
      event = FactoryBot.create(:event,documents:[doc])
      refute_empty event.documents
      assert_equal [doc],event.documents
    end
  end

  test 'fails to link to none visible document' do
    person = FactoryBot.create(:person)
    User.with_current_user(person.user) do
      doc = FactoryBot.create(:document)
      refute doc.can_view?
      event = FactoryBot.build(:event,documents:[doc], contributor:person)

      refute event.save

      event = FactoryBot.create(:event,contributor:person)
      assert event.valid?

      assert_raise(ActiveRecord::RecordNotSaved) do
        event.documents << doc
        event.save!
      end
      
    end
  end

  test 'country conversion and validation' do

    event = FactoryBot.build(:event)
    assert event.valid?
    assert event.country.nil?

    event.country = ''
    assert event.valid?

    event.country = 'GB'
    assert event.valid?
    assert_equal 'GB', event.country

    event.country = 'gb'
    assert event.valid?
    assert_equal 'GB', event.country

    event.country = 'Germany'
    assert event.valid?
    assert_equal 'DE', event.country

    event.country = 'FRANCE'
    assert event.valid?
    assert_equal 'FR', event.country

    event.country = 'ZZ'
    refute event.valid?
    assert_equal 'ZZ', event.country

    event.country = 'Land of Oz'
    refute event.valid?
    assert_equal 'Land of Oz', event.country

    # check the conversion gets saved
    event = FactoryBot.build(:event)
    event.country = "Germany"
    disable_authorization_checks {
      assert event.save!
    }
    event.reload
    assert_equal 'DE',event.country

  end

  test 'time zone validation' do
    event = FactoryBot.build(:event)
    assert event.valid?
    event.time_zone = 'invalid/time_zone'
    refute event.valid?
  end

  test 'time should change according to the time zone' do
    event = FactoryBot.create(:event, start_date: '2022-02-25 14:11:00', end_date: '2022-12-25 2:58:00',
                            time_zone: 'Europe/Paris')

    start_date = event.start_date
    end_date =  event.end_date
    new_time_zone = 'Asia/Tehran'

    disable_authorization_checks do
      event.time_zone = new_time_zone
      event.save!
    end

    assert_equal start_date.to_s(:db).in_time_zone(new_time_zone), event.start_date
    assert_equal end_date.to_s(:db).in_time_zone(new_time_zone), event.end_date
  end

  test 'should not shift times on subsequent saves' do
    event = FactoryBot.create(:event, time_zone: 'Europe/Paris')

    start_date = event.start_date
    end_date = event.end_date
    disable_authorization_checks do
      event.description = 'New description on first save.'
      event.save!
    end
    assert_equal start_date, event.start_date
    assert_equal end_date, event.end_date

    disable_authorization_checks do
      event.description = 'New description on second save.'
      event.save!
    end
    assert_equal start_date, event.start_date
    assert_equal end_date, event.end_date
  end

  test 'should update date time on time zone change' do
    event = FactoryBot.create(:event, time_zone: 'Europe/Paris')
    start_date = event.start_date
    end_date = event.end_date

    disable_authorization_checks do
      event.time_zone = 'Asia/Tehran'
      event.save!
    end

    assert_not_equal start_date, event.start_date
    assert_not_equal end_date, event.end_date
  end
  
end
