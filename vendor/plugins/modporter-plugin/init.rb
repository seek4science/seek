# Include hook code here
require 'mod_porter'

class ActionController::Base
  include ModPorter::Filter
end
