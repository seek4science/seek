# app/controllers/annotations_controller.rb
#
# This extends the AnnotationsController controller defined in the Annotations gem.

#require_dependency File.join(Gem.loaded_specs['my_annotations'].full_gem_path,'lib','app','controllers','annotations_controller')

class AnnotationsController < ApplicationController
  include Annotations
  def show
      annotation = Annotation.find(params[:id])
      other_annotations = annotation.value.annotations


      @other_tagging_assets = []
      other_annotations.each do |annotation|
        annotatable=annotation.annotatable
        @other_tagging_assets << annotatable unless @other_tagging_assets.include?(annotatable)
      end

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

end
