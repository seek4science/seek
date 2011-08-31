# app/controllers/annotations_controller.rb
#
# This extends the AnnotationsController controller defined in the Annotations plugin.

require_dependency File.join(Rails.root, 'vendor', 'plugins', 'annotations', 'lib', 'app', 'controllers', 'annotations_controller')

class AnnotationsController < ApplicationController
  include Annotations
  unloadable
  def show
      @original_tag = Annotation.find(params[:id])
      @other_tagging_annotations = Annotation.find(:all, :conditions=> "value_id = '#{@original_tag.value_id}'")

      @other_tagging_assets = []
      @other_tagging_annotations.each do |annotation|
        @other_tagging_assets << (annotation.source_type).find(annotation.source_id)
      end


      #TextValue.find(:all, @original_tag.value_id).each do

      if @other_tagging_assets.empty?
        flash.now[:notice]="No objects (or none that you are authorized to view) are tagged with '<b>#{@original_tag.value.text}</b>'."
      else
        flash.now[:notice]="#{@other_tagging_assets.size} #{@other_tagging_assets.size==1 ? 'item' : 'items'} tagged with '<b>#{@original_tag.value.text}</b>'."
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

