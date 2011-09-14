# app/controllers/annotations_controller.rb
#
# This extends the AnnotationsController controller defined in the Annotations plugin.

require_dependency File.join(Rails.root, 'vendor', 'plugins', 'annotations', 'lib', 'app', 'controllers', 'annotations_controller')

class AnnotationsController < ApplicationController
  include Annotations
  unloadable
  def show
      annotation = Annotation.find(params[:id])
      other_annotations = annotation.value.annotations


      @other_tagging_assets = []
      other_annotations.each do |annotation|
        annotatable=annotation.annotatable
        @other_tagging_assets << annotatable unless @other_tagging_assets.include?(annotatable)
      end


      #TextValue.find(:all, @original_tag.value_id).each do

      if @other_tagging_assets.empty?
        flash.now[:notice]="No objects (or none that you are authorized to view) are tagged with '<b>#{annotation.value.text}</b>'."
      else
        flash.now[:notice]="#{@other_tagging_assets.size} #{@other_tagging_assets.size==1 ? 'item' : 'items'} tagged with '<b>#{annotation.value.text}</b>'."
      end
      respond_to do |format|
        format.html # show.html.erb
      end
    end

    def index
      respond_to do |format|
        format.html
      end
    end

    private

    #Removes all results from the search results collection passed in that are not Authorised to show for the current_user
    def select_authorised collection
      collection.select {|el| el.can_view?}
    end

end

