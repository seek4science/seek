module Seek
  module Openbis
    #to store and pass about the connection info - for the purposes of the demo only
    #this is bad practice and not threadsafe or secure
    class ConnectionInfo
      include Singleton
      attr_accessor :as_endpoint,:dss_endpoint,:session_token

      def self.setup username,password,as_endpoint,dss_endpoint
        me = self.instance
        me.as_endpoint=as_endpoint
        me.dss_endpoint=dss_endpoint
        me.session_token = Fairdom::OpenbisApi::Authentication.new(username, password, as_endpoint).login["token"]
      end
    end
  end
end