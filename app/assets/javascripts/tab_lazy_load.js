function load_tabs() {
    var tabberOptions = {'onLoad':function() {
        displayTabs();
    }};
    tabberAutomatic(tabberOptions);
}

function tab_on_click(resource_type, resource_ids, with_facets) {
    var tab_content_id = 'faceted_search_result';

    var click_tab = document.getElementById('tab_' + resource_type);
    var url = '';
    if (with_facets == true)
        url = items_for_facets_url;
    else
        url = items_for_result_url;

    click_tab.onclick = function () {
        show_large_ajax_loader(tab_content_id);
        deactivate_previous_tab();
        click_tab.className = 'tabberactive';

        Exhibit.SelectionState.currentAssetType = resource_type;

        jQuery.noConflict();
        var $j = jQuery;
        $j.ajax({
            url: url,
            async: false,
            data: { item_ids: resource_ids,
                item_type: resource_type}
        })
            .done(function (data) {
                var tab_content = $j('#' + tab_content_id);
                if (with_facets == true)
                    tab_content.html(data.items_for_facets);
                else
                    tab_content.html(data.items_for_result);
                //$j(document).ready(initializationFunction);
                //$j(document).trigger("scriptsLoaded.exhibit");
            });
    }
}

function deactivate_previous_tab(){
    //First change the color of the previous chosen tab
    var previous_active_tab = document.getElementsByClassName('tabberactive')[0];
    if (previous_active_tab != null)
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

//this is for the case of one exhibit instance.
function tab_on_click_one_facet(resource_type) {
    var click_tab = document.getElementsByClassName(resource_type)[0];
    click_tab.onclick = function () {
        deactivate_previous_tab();
        //Hide all the tab content
        hide_all_tabs_content();
        //Hide more-facets for previous clicked tab
        hide_specified_facets();
        //Activate the clicking tab
        click_tab.parentElement.className = 'tabberactive';
        //Show the content of clicking tab
        $j('#' + resource_type).removeClass('tabbertabhide');

        show_specified_facets_for_active_tab(resource_type);
    }
}

//this is for the case of one exhibit instance.
function hide_specified_facets(){
    $j(".specified_facets").hide();
}

//this is for the case of one exhibit instance.
function hide_specified_facet_list(){
    $j(".specified_facet_list").hide();
}

//this is for the case of one exhibit instance.
function hide_all_tabs_content(){
    var all_tabs_content = $j('.tabbertab');
    for (var i=0; i<all_tabs_content.length; i++){
        var tab = all_tabs_content[i];
        var class_name = tab.className;
        if (class_name.match('tabbertabhide') == null){
            tab.className = tab.className + ' tabbertabhide';
        }
    }
}

//this is for the case of one exhibit instance.
function show_specified_facets_for_active_tab(active_tab) {
    var more_facet_id = "specified_" + active_tab + "_facets";
    $j('#' + more_facet_id).show();
}