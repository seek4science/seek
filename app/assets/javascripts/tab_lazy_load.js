function load_tabs() {
    var tabberOptions = {'onLoad':function() {
        displayTabs();
    }};
    tabberAutomatic(tabberOptions);
}

function tab_on_click(scale_title, resource_type, resource_ids, actions_partial_disable){
    var click_tab = document.getElementsByClassName(scale_title + '_' + resource_type)[0];
    click_tab.onclick = function(){
        deactivate_previous_tab(this);
        click_tab.parentElement.className = 'tabberactive';

        //if the content of the click_tab is already loaded, just show it, otherwise call ajax to get the content
        var tab_content_view_some_id = scale_title + '_' + resource_type + '_view_some';
        var tab_content_view_some = $(tab_content_view_some_id);
        var tab_content_view_all_id = scale_title + '_' + resource_type + '_view_all';
        var tab_content_view_all = $(tab_content_view_all_id);
        if (tab_content_view_all.childNodes.length > 0){
            tab_content_view_all.show();
        }else if (tab_content_view_some.childNodes.length > 0){
            tab_content_view_some.show();
        }else{
            tab_content_view_some.show();
            request = new Ajax.Request('/application/resource_in_tab',
                {
                    method: 'post',
                    parameters: {
                        resource_type: resource_type,
                        resource_ids: resource_ids,
                        scale_title: scale_title,
                        view_type: 'view_some',
                        actions_partial_disable: actions_partial_disable
                    },
                    onLoading: show_large_ajax_loader(tab_content_view_some_id),
                    onFailure: function(transport){
                        alert('Something went wrong, please try again...');
                    }
                });
        }
    };

}
function deactivate_previous_tab(tab_element){
        var previous_active_tab = tab_element.up("ul.tabbernav").getElementsByClassName('tabberactive')[0];
        previous_active_tab.className = '';
        //Then hide the content of the tab
        var scale_and_type = previous_active_tab.childNodes[0].className;
        //the content could come from external search
        if (scale_and_type.match("external_result") != null){
            scale_and_type = scale_and_type.split('external_result')[0];
            var resource_type = scale_and_type.split('_')[1].strip();
            var external_tab_content = $(resource_type);
            if (external_tab_content != null){
                external_tab_content.hide();
            }
        }else{
            var scale = scale_and_type.split('_')[0].strip();
            var resource_type = scale_and_type.split('_')[1].strip();
            var tab_content_view_some_id = scale + '_' + resource_type + '_view_some';
            var tab_content_view_all_id = scale + '_' + resource_type + '_view_all';
            var tab_content_view_some = $(tab_content_view_some_id);
            var tab_content_view_all = $(tab_content_view_all_id);
            if (tab_content_view_some != null){
                tab_content_view_some.hide();
            }
            if (tab_content_view_all != null){
                tab_content_view_all.hide();
            }
        }
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
    };
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