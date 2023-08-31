module Fairdom
  module OpenbisApi
    module MockAuthentication
      def login
        { 'token' => 'a token' }
      end
    end
  end
end

module Fairdom
  module OpenbisApi
    module RecordQuery
      def query(options)
        path = mock_file_path(options)
        response = super(options)
        File.open(path, 'w+') do |file|
          file.write(JSON.generate(response))
        end
        response
      end

      def mock_file_path(options)
        name = Digest::SHA2.hexdigest(options.inspect) + '.json'
        dir = File.join(Rails.root, 'test', 'fixtures', 'files', 'mocking', 'openbis')
        FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
        File.join(dir, name)
      end
    end
  end
end

module Fairdom
  module OpenbisApi
    module MockedQuery
      # debug is with puts so it can be easily seen on tests screens
      DEBUG = Seek::Config.openbis_debug ? true : false

      def query(options)
        path = mock_file_path(options)
        response = File.open(path).read
        JSON.parse(response)
      end

      def mock_file_path(options)
        name = Digest::SHA2.hexdigest(options.inspect) + '.json'
        puts "Mock query, File: #{name} #{options}" if DEBUG
        dir = File.join(Rails.root, 'test', 'fixtures', 'files', 'mocking', 'openbis')
        File.join(dir, name)
      end

      def mocked?
        true
      end
    end
  end
end

def mock_openbis_calls
  Fairdom::OpenbisApi::ExplicitMockedQuery.clear

  Fairdom::OpenbisApi::Authentication.class_eval do
    prepend Fairdom::OpenbisApi::MockAuthentication
  end
  Fairdom::OpenbisApi::ApplicationServerQuery.class_eval do
    prepend Fairdom::OpenbisApi::MockedQuery
  end
  Fairdom::OpenbisApi::DataStoreQuery.class_eval do
    prepend Fairdom::OpenbisApi::MockedQuery
  end
end

def record_openbis_calls
  Fairdom::OpenbisApi::ApplicationServerQuery.class_eval do
    prepend Fairdom::OpenbisApi::RecordQuery
  end
  Fairdom::OpenbisApi::DataStoreQuery.class_eval do
    prepend Fairdom::OpenbisApi::RecordQuery
  end
end

def openbis_linked_data_file(user = User.current_user, endpoint = nil)
  User.with_current_user(user) do
    endpoint ||= FactoryBot.create(:openbis_endpoint, project:user.person.projects.first)
    set = Seek::Openbis::Dataset.new(endpoint, '20160210130454955-23')

    df = Seek::Openbis::SeekUtil.new.createDataFileFromObisSet(set, user)
    # df = DataFile.build_from_openbis(endpoint, '20160210130454955-23')
    assert df.openbis?
    df.save!
    df
  end
end

module Fairdom
  module OpenbisApi
    module ExplicitMockedQuery
      # debug is with puts so it can be easily seen on tests screens
      DEBUG = Seek::Config.openbis_debug ? true : false

      @@hits = {}

      def self.set_hit(id, val)
        @@hits[id] = val
      end

      def self.get_hit(id)
        @@hits[id]
      end

      def self.clear
        @@hits = {}
      end

      def query(options)
        puts "Explicit mocked query: #{options}" if DEBUG
        id = options[:attributeValue]
        return file_query(options) unless id

        res = Fairdom::OpenbisApi::ExplicitMockedQuery.get_hit(id)
        puts "Not set mocked value for id: #{id}" if DEBUG && !res
        res ? res : file_query(options)
      end

      def file_query(options)
        path = mock_file_path(options)
        response = File.open(path).read
        JSON.parse(response)
      end

      def mock_file_path(options)
        name = Digest::SHA2.hexdigest(options.inspect) + '.json'
        puts "Mock query, File: #{name} #{options}" if DEBUG
        dir = File.join(Rails.root, 'test', 'fixtures', 'files', 'mocking', 'openbis')
        File.join(dir, name)
      end
    end
  end
end

def set_mocked_value_for_id(id, val)
  Fairdom::OpenbisApi::ExplicitMockedQuery.set_hit(id, val)
end

def explicit_query_mock
  Fairdom::OpenbisApi::ExplicitMockedQuery.clear

  Fairdom::OpenbisApi::ApplicationServerQuery.class_eval do
    prepend Fairdom::OpenbisApi::ExplicitMockedQuery
  end
end
