function updateFirstPage(){
    //temporary put this function here, need to find better place or rename the updateFirstPage
    renameHFMissingField();
    var items = Exhibit.jQuery('div[itemid]');
    var item_type = getItemType(items);
    var item_ids = getItemIds(items);

    if (item_type != null && item_ids.length > 0){
        Exhibit.jQuery.ajax({
            url: faceted_items_url,
            data: {item_ids: item_ids, item_type: item_type}
        })
        .done(function( data ) {
                updateContent(data.resource_list_items);

                Exhibit.jQuery('.exhibit-viewPanel').removeClass('exhibit-ui-protection');
                Exhibit.jQuery('.exhibit-collectionView-header-groupControl').hide();
                Exhibit.jQuery('.exhibit-toolboxWidget-button').hide();
                decodeValueTooltip();

                Exhibit.jQuery('.exhibit-viewPanel-viewContainer').show();
        });
    }
}

window.onload = function(){
    Exhibit.jQuery(document).on( "exhibitConfigured.exhibit", function() {
        defaultSearchText();
    });

    Exhibit.jQuery(document).on( "onItemsChanged.exhibit", function() {
        updateFirstPage();
    });
};

function defaultSearchText(default_text){
    Exhibit.jQuery.noConflict();
    var $j = Exhibit.jQuery;
    var default_text = 'Search filters below';
    $j('div[id="facet_search_box"] input').each(function(){
        $j(this).attr('placeholder',default_text);
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

//rename Hierachical Facet Missing Field of the root level: from others to missing this field
function renameHFMissingField(){
    var missing_field_elements = Exhibit.jQuery('.exhibit-flowingFacet-body').children("[title='(others)']");
    var replaced_term = "(missing this field)";
    missing_field_elements.map(function(){
        Exhibit.jQuery(this).attr("title", replaced_term);
        var value_link = Exhibit.jQuery(this).children('.exhibit-flowingFacet-value-link');
        value_link.html("<span class='exhibit-facet-value-missingThisField'>(missing this field)</span>");
    })
}

