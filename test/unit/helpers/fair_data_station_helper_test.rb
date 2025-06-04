require 'test_helper'

class FairDataStationHelperTest < ActionView::TestCase

  test 'show_update_from_fair_data_station_button?' do
    person = FactoryBot.create(:person)
    person2 = FactoryBot.create(:person)

    inv = FactoryBot.create(:investigation, external_identifier:'test-inv-identifier', contributor: person)
    inv2 = FactoryBot.create(:investigation, external_identifier:'', contributor: person)

    with_config_value(:fair_data_station_enabled, true) do
      User.with_current_user(person.user) do
        assert show_update_from_fair_data_station_button?(inv)
        refute show_update_from_fair_data_station_button?(inv2)
      end

      User.with_current_user(person2.user) do
        refute show_update_from_fair_data_station_button?(inv)
        refute show_update_from_fair_data_station_button?(inv2)
      end
    end

    with_config_value(:fair_data_station_enabled, false) do
      User.with_current_user(person.user) do
        refute show_update_from_fair_data_station_button?(inv)
      end
    end

  end

end