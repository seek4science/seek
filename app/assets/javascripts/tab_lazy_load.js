function load_tabs() {
    var tabberOptions = {'onLoad':function() {
        displayTabs();
    }};
    tabberAutomatic(tabberOptions);
}

function tab_on_click(scale_title, resource_type, resource_ids){
    var click_tab = document.getElementsByClassName(scale_title + '_' + resource_type)[0];
    click_tab.onclick = function(){
        deactivate_previous_tab(scale_title);
        click_tab.parentElement.className = 'tabberactive';
        jQuery.noConflict();
        var $j = jQuery;
        $j.ajax({
            url: search_items_url,
            async: false,
            data: { item_ids: resource_ids.split(','),
                    item_type: resource_type}
        })
        .done(function( data ) {
            var tab_content_id = scale_title + '_' + 'faceted_search_result';
            $j('#' + tab_content_id).html(data.facets_for_items);
            Exhibit.jQuery(document).trigger("scriptsLoaded.exhibit");
        });
    }
}

function deactivate_previous_tab(scale_title){
    //First change the color of the previous chosen tab
    var scale_result = $(scale_title + '_results');
    var previous_active_tab = scale_result.getElementsByClassName('tabberactive')[0];
    previous_active_tab.className = '';
}

function check_tab_content(show_tab_content_id, hide_tab_content_id){
    var tab_content = $(show_tab_content_id);
    if (tab_content.childNodes.length > 0){
        tab_content.show();
        $(hide_tab_content_id).hide();
        //refresh_boxover_tooltip_position, so it does not create the blank at the end of the page when switching from -view all- to -view some- items
        refresh_boxover_tooltip_position();
        return false;
    }else{
        return true;
    }
}

function refresh_boxover_tooltip_position(){
    var boxover_tooltip = document.getElementsByClassName('boxoverTooltipBody')[0];
    if (boxover_tooltip != null){
        boxover_tooltip.parentNode.style['top']='0px';
    }
}

//this is the case of search that include the result from external resources
//check if no internal result is found and no tab was chosen, then display the first external tab
function display_first_external_tab_content(scale_title){
    var scaled_result = $(scale_title + "_results");
    var scaled_all_tabs_count = scaled_result.getElementsByClassName('tabbertab').length;
    var scale_external_tabs_count = scaled_result.getElementsByClassName('external_result').length/2;
    var previous_active_tab = scaled_result.getElementsByClassName('tabberactive')[0];
    if ((scaled_all_tabs_count == scale_external_tabs_count) && (previous_active_tab == null)){
        var click_tab = scaled_result.getElementsByClassName('external_result')[0];
        if (click_tab != null){
            click_tab.click();
        }
    }
}

//this is the case of search that include the result from external resources
function external_tab_on_click(scale_title, resource_type){
    var click_tab = document.getElementsByClassName(scale_title + '_' + resource_type)[0];
    click_tab.onclick = function(){
        deactivate_previous_tab(scale_title);
        click_tab.parentElement.className = 'tabberactive';
        $(resource_type).show();
    }
}

//this is the case of search that include the result from external resources
//if the external tab was chosen for this scale, then display its content
function display_external_tab_content(scale_title){
    var scaled_result = $(scale_title + "_results");
    var chosen_tab = scaled_result.getElementsByClassName('tabberactive')[0];
    var scale_and_type = chosen_tab.childNodes[0].className;
    //the content could come from external search
    if (scale_and_type.match("external_result") != null){
        scale_and_type = scale_and_type.split('external_result')[0];
        var resource_type = scale_and_type.split('_')[1].strip();
        $(resource_type).show();
    }

}