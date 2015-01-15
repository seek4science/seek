jQuery(document).ready(function(){
    jQuery(document).on("exhibitConfigured.exhibit", function() {
        //need to show those facet list from beginning for exhibit to construct them, otherwise it can not
        //after that hide them here
        hide_specified_facet_list();
    });
});

function load_tabs() {
    var tabberOptions = {'onLoad':function() {

    }};
    tabberAutomatic(tabberOptions);
}

//params items: e.g. Model_1,Model_2,...
function generateParamItems(resource_type, resource_ids){
    var items = resource_type + '_';
    items = items + resource_ids.replace(/,/g, ',' + resource_type + '_');
    return items;
}

function deactivate_previous_tab(){
    //First change the color of the previous chosen tab
    var previous_active_tab = document.getElementsByClassName('tabberactive')[0];
    if (previous_active_tab != null)
        previous_active_tab.className = '';
}

function tab_on_click(resource_type) {
    var click_tab = document.getElementsByClassName(resource_type)[0];
    click_tab.onclick = function () {
        deactivate_previous_tab();
        //Hide all the tab content
        hide_all_tabs_content();
        //Hide more-facets for previous clicked tab
        hide_specified_facets();
        //Activate the clicking tab
        click_tab.parentElement.className = 'tabberactive';
        active_tab = resource_type;
        //Show the content of clicking tab
        //(does not work with jquery)
        document.getElementById(resource_type).className = 'tabbertab';

        show_specified_facets_for_active_tab(resource_type);
    }
}

function displayMoreLink(){
    $j(".more_link").show();
}

function hide_specified_facets(){
    $j(".specified_facets").hide();
}

function hide_specified_facet_list(){
    $j(".specified_facet_list").hide();
}

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

function show_specified_facets_for_active_tab(active_tab) {
    var more_facet_id = "specified_" + active_tab + "_facets";
    //(does not work with jquery)
    var more_facet_element = document.getElementById(more_facet_id);
    if (more_facet_element != null)
        more_facet_element.show();

    //display more-link for the first time
    var more_link = $('more_' + active_tab);
    var less_link = $('less_' + active_tab);

    if (more_link != null)
        if (more_link.offsetParent == null && less_link.offsetParent == null)
            more_link.show();
}