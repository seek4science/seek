class TagsController < ApplicationController
  before_action :find_tag, only: [:show]
  before_action :find_tagged_objects, only: [:show]

  def show
    if @tagged_objects.empty?
      flash.now[:notice] = "No objects (or none that you are authorized to view) are tagged with '<b>#{h(@tag.text)}</b>'.".html_safe
    else
      flash.now[:notice] = "#{@tagged_objects.size} #{'item'.pluralize(@tagged_objects.size)} tagged with '<b>#{h(@tag.text)}</b>'.".html_safe
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

  def query
    q = params[:q] || ''
    @tags = get_tags.where('text LIKE ?', "%#{q}%").limit(100).map(&:text)
    results = {
      results: @tags.collect do |tag|
       { id: tag, text: tag}
      end
    }
    respond_to do |format|
      format.json { render json: results.to_json }
    end
  end

  private

  def find_tag
    @tag = TextValue.find_by_id(params[:id])
    unless @tag
      flash[:error] = 'The Tag does not exist'
      respond_to do |format|
        format.html { redirect_to all_anns_path }
      end
    end
  end

  def find_tagged_objects
    types = tag_types_for_selection
    @tagged_objects = @tag.annotations.with_attribute_name(types).collect(&:annotatable).uniq.compact.select(&:can_view?)
  end

  def tag_types_for_selection
    types = if params[:type]
              [params[:type]]
            else
              TextValue::TAG_TYPES
            end
    types
  end

  def get_tags
    attribute = AnnotationAttribute.where(name: params[:type] || 'tag').first
    TextValue.select(:text)
             .joins("LEFT OUTER JOIN annotations ON annotations.value_id = text_values.id AND annotations.value_type = 'TextValue'" 'LEFT OUTER JOIN annotation_value_seeds ON annotation_value_seeds.value_id = text_values.id')
             .where('annotations.attribute_id = :attribute_id OR annotation_value_seeds.attribute_id = :attribute_id', attribute_id: attribute.try(:id)).distinct
  end
end
