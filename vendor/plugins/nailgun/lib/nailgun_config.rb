module Nailgun
  class NailgunConfig
    # default options
    class << self
      attr_accessor :options
    end
    NailgunConfig.options= {
      :java_bin => "java",
      :server_address => 'localhost',
      :port_no=>'2113',
      :run_mode => :once
    }
  end
end
