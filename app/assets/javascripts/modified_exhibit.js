function updateFirstPage(){
    var items = Exhibit.jQuery('div[itemid]');
    var item_type = getItemType(items);
    var item_ids = getItemIds(items);

    Exhibit.jQuery.ajax({
        url: faceted_items_url,
        data: {item_ids: item_ids, item_type: item_type}
    })
    .done(function( data ) {
            updateContent(data.resource_list_items);

            Exhibit.jQuery('.exhibit-viewPanel').removeClass('exhibit-ui-protection');
            Exhibit.jQuery('.exhibit-collectionView-header-groupControl').hide();
            decodeValueTooltip();

            Exhibit.jQuery('.exhibit-viewPanel-viewContainer').show();

    });
}

function getItemIds(items){
    var item_ids = items.map(function(){
        var exhibit_item_id = Exhibit.jQuery(this).attr("itemid");
        return database.getObject(exhibit_item_id, 'item_id');
    }).get();

    return item_ids;
}

function getItemType(items){
    return database.getObject(items.attr("itemid"), 'type');
}

function updateContent(resource_list_items){
    var collection_view_body = Exhibit.jQuery('.exhibit-collectionView-body');
    collection_view_body.html(resource_list_items);
}

function decodeValueTooltip(){
    Exhibit.jQuery('.exhibit-facet-value').map(function(){
        var title = Exhibit.jQuery(this).attr("title");
        Exhibit.jQuery(this).attr("title", decodeHTML(title));
    })
}

