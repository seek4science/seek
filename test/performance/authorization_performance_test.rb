require 'test_helper'
require 'ruby-prof'

class AuthorizationPerformanceTest < ActiveSupport::TestCase
  test 'profile authorizing data file' do
    user = Factory(:user)
    data_files = FactoryGirl.create_list(:data_file, 10)

    result = RubyProf.profile do
      data_files.each do |data_file|
        data_file.can_view?(user)
      end
    end

    printer = RubyProf::FlatPrinter.new(result)
    printer.print(STDOUT, min_percent: 1)
  end
end
