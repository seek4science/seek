function load_tabs() {
    var tabberOptions = {'onLoad':function() {
        displayTabs();
    }};
    tabberAutomatic(tabberOptions);
}

function tabs_on_click(scale_title, resource_type, resource_ids){
    var click_tab = document.getElementsByClassName(scale_title + '_' + resource_type)[0];
    click_tab.onclick = function(){
        deactivate_previous_tab(scale_title);
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
                method: 'get',
                parameters: {
                    resource_type: resource_type,
                    resource_ids: resource_ids,
                    scale_title: scale_title,
                    view_type: 'view_some'
                },
                onLoading: show_large_ajax_loader(tab_content_view_some_id),
                onFailure: function(transport){
                    alert('Something went wrong, please try again...');
                }
            });
        }
    }

}

function deactivate_previous_tab(scale_title){
    //First change the color of the previous chosen tab
    var scale_result = $(scale_title + '_results');
    var previous_active_tab = scale_result.getElementsByClassName('tabberactive')[0];
    previous_active_tab.className = '';
    //Then hide the content of the tab
    var scale_and_type = previous_active_tab.childNodes[0].className;
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
