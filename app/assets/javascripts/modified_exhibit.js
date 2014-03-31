function updateFirstPage(){
    var items = Exhibit.jQuery('div[itemid]');
    var item_ids = items.map(function(){
        var exhibit_item_id = Exhibit.jQuery(this).attr("itemid");
        return database.getObject(exhibit_item_id, 'item_id');
    }).get();

    Exhibit.jQuery.ajax({
        url: "http://localhost:3001/assays/filtered_items",
        data: {item_ids: item_ids, item_type: 'Assay'}
    })
    .done(function( data ) {
            var resource_list_items = data.resource_list_items;
            var groups = Exhibit.jQuery('.exhibit-collectionView-group');
            if (groups.length > 0){
                groups.map(function() {
                    var count = Exhibit.jQuery(this).children('h1').children('.exhibit-collectionView-group-count').children('span').text();
                    var updated_group_content = resource_list_items.slice(0,count).join(' ');
                    resource_list_items = resource_list_items.slice(count);
                    Exhibit.jQuery(this).children('.exhibit-collectionView-group-content').html(updated_group_content);
                });
            }else{
                var collection_view_body = Exhibit.jQuery('.exhibit-collectionView-body');
                collection_view_body.html(resource_list_items.join(' '));
            }

            Exhibit.jQuery('div.exhibit-viewPanel').removeClass('exhibit-ui-protection');
            Exhibit.jQuery('.exhibit-viewPanel-viewContainer').show();

    });
}

