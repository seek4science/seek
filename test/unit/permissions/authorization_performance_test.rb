require 'test_helper'
require 'ruby-prof'

class AuthorizationPerformanceTest < ActiveSupport::TestCase
  test 'profile authorizing data file' do
    user = Factory(:user)
    data_files = []
    i = 0
    while i < 10
      data_files << Factory(:data_file, title: "data file #{i}")
      i += 1
    end

    result = RubyProf.profile do
      data_files.each do |data_file|
        data_file.can_view?(user)
      end
    end

    printer = RubyProf::FlatPrinter.new(result)
    printer.print(STDOUT, min_percent: 1)
  end
end
