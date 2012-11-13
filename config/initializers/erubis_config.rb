require 'erubis/helpers/rails_helper'

Erubis::Helpers::RailsHelper.engine_class = Erubis::Eruby
Erubis::Helpers::RailsHelper.preprocessing = true
Erubis::Helpers::RailsHelper.init_properties = {:bufvar => '@output_buffer'}