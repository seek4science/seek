module Seek
  module FacetedBrowsing
    def items_for_result
      if request.env['HTTP_REFERER'].include?('/search')
        items_for_result = items_for_search_result
      else
        items_for_result = items_for_browsing_result
      end

      respond_to do |format|
        format.json do
          render json: { status: 200, items_for_result: items_for_result }
        end
      end
    end

    private

    def items_for_search_result
      type_id_hash = get_type_id_hash
      items = []
      type_id_hash.each do |type, ids|
        if Seek::Util.searchable_types.collect(&:name).include?(type)
          items |= get_items type, ids
        else
          items |= get_external_items ids
        end
      end

      resource_hash = ApplicationHelper.classify_for_tabs(items)
      active_tab = params[:active_tab]

      render_to_string partial: 'assets/resource_tabbed_one_facet',
                       locals: { resource_hash: resource_hash,
                                 display_immediately: true,
                                 active_tab: active_tab }
    end

    def items_for_browsing_result
      type_id_hash = get_type_id_hash
      items = []
      type_id_hash.each do |type, ids|
        items |= get_items type, ids
      end

      items.collect { |item| render_to_string partial: 'assets/resource_list_item', object: item }.join(' ')
    end

    def get_items(item_type, item_ids)
      items = []
      item_ids.collect!(&:to_i)
      unless item_type.blank?
        clazz = item_type.constantize
        items = clazz.where(id: item_ids).authorized_for('view').to_a
      end

      items.sort! { |a, b| item_ids.index(a.id) <=> item_ids.index(b.id) }
      items
    end

    def get_type_id_hash
      items_type_id = (params[:items] || '').split(',')
      type_id_hash = {}
      items_type_id.each do |type_id|
        type, id = type_id.split('_')
        if type_id_hash[type].nil?
          type_id_hash[type] = [id]
        else
          type_id_hash[type] << id
        end
      end
      type_id_hash
    end

    def get_external_items(ids)
      external_items = []
      ids.each do |id|
        external_items << SearchController.new.external_item(id)
      end
      external_items.compact.flatten.uniq
    end
  end
end
