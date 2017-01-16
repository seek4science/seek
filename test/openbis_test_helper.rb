module Fairdom
  module OpenbisApi
    module MockAuthentication
      def login
        {'token'=>'a token'}
      end
    end
  end
end


module Fairdom
  module OpenbisApi
    module RecordQuery
      def query options
        path = mock_file_path(options)
        response = super(options)
        File.open(path,'w+') do |file|
          file.write(JSON.generate(response))
        end
        response
      end

      def mock_file_path(options)
        name=Digest::SHA2.hexdigest(options.inspect)+".json"
        dir = File.join(Rails.root,'test','fixtures','files','mocking','openbis')
        FileUtils.mkdir_p(dir) unless Dir.exists?(dir)
        File.join(dir,name)
      end
    end
  end
end

module Fairdom
  module OpenbisApi
    module MockedQuery
      def query options
        path = mock_file_path(options)
        response = File.open(path).read
        JSON.parse(response)
      end

      def mock_file_path(options)
        name=Digest::SHA2.hexdigest(options.inspect)+".json"
        dir = File.join(Rails.root,'test','fixtures','files','mocking','openbis')
        File.join(dir,name)
      end
    end
  end
end

def mock_openbis_calls
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