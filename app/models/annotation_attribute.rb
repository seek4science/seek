# app/models/annotation_attribute.rb
#
# This extends the AnnotationAttribute model defined in the Annotations plugin.

require_dependency File.join(Rails.root, 'vendor', 'plugins', 'annotations', 'lib', 'app', 'models', 'annotation_attribute')

class AnnotationAttribute < ActiveRecord::Base
end
