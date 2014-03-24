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
        var tileViewBody = Exhibit.jQuery('.exhibit-tileView-body');
            tileViewBody.html(data.resource_list_items);
            Exhibit.jQuery('.exhibit-viewPanel-viewContainer').show();
    });
}

