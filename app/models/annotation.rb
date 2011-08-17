# app/models/annotation.rb
#
# This extends the Annotation model defined in the Annotations plugin.

require_dependency File.join(Rails.root, 'vendor', 'plugins', 'annotations', 'lib', 'app', 'models', 'annotation')

class Annotation < ActiveRecord::Base
end
