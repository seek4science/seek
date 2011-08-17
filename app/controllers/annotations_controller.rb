# app/controllers/annotations_controller.rb
#
# This extends the AnnotationsController controller defined in the Annotations plugin.

require_dependency File.join(Rails.root, 'vendor', 'plugins', 'annotations', 'lib', 'app', 'controllers', 'annotations_controller')

class AnnotationsController < ApplicationController
end
