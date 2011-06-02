function check_clicked(){
    $('check_button').value = "Submitting ...";
    $('check_button').disabled = true;
    $('form').submit();
}

function annotate_clicked(){
    $('annotate_button').value = "Submitting ...";
    $('annotate_button').disabled = true;
    $('form').following_action.value = "annotate";
    $('form').submit();
}

function simulate_clicked(){
    $('simulate_button').value = "Submitting ...";
    $('simulate_button').disabled = true;
    $('steadystateanalysis').value = $('steadystate').value;
    $('form').following_action.value = "simulate";
    $('form').submit();
}

function save_new_version_clicked(){
    $('new_version_comments').value = $('new_version_comments_rb').value;
    $('new_version_filename').value = $('new_version_filename_rb').value;
    $('new_version_options').hide();
    $('new_version_waiting').show();
    $('new_version_button').value = "Submitting ...";
    $('new_version_button').disabled = true;
    $('form').following_action.value = "save_new_version";
    $('form').saved_model_format.value = $('model_format').value;
    $('form').submit();
}

function create_panel_cookies() {
    create_panel_cookies_by_id('name_panel');
    create_panel_cookies_by_id('reactions_panel');
    create_panel_cookies_by_id('equations_panel');
    create_panel_cookies_by_id('assignments_panel');
    create_panel_cookies_by_id('initial_panel');
    create_panel_cookies_by_id('parameters_panel');
    create_panel_cookies_by_id('functions_panel');
    create_panel_cookies_by_id('events_panel');
    create_panel_cookies_by_id('annotated_reactions_panel');
    create_panel_cookies_by_id('annotated_species_panel');
    
//    if ($('plotGraphPanel').value == "on") {
//        createCookie5(rc, rtreaction, 1, 'rc');
//    }
    if ($('plotKineticsPanel').value == "on") {
        createCookie6(rc2, rtkinetics, 1, 'rc2');
    }        
}

var rtHash = new Array();

function map_rt_elements(){
    rtHash['name_panel'] = rtmodelname;
    rtHash['reactions_panel'] = rtreaction;
    rtHash['equations_panel'] = rtkinetics;
    rtHash['assignments_panel'] = rtassignmentRules;
    rtHash['initial_panel'] = rtinitVal;
    rtHash['parameters_panel'] = rtparameterset;
    rtHash['functions_panel'] = rtfunctions;
    rtHash['events_panel'] = rtevents;
}


function create_panel_cookies_by_id(id){
    try {
        createCookie(id, 1);
        rtElement = rtHash[id];
        
        createCookie2(rtElement, 1, id + "_rt");
    } 
    catch (err) {
    }
    
}

function read_panel_cookies(){
    read_panel_cookies_from_id('name_panel');
    read_panel_cookies_from_id('reactions_panel');
    read_panel_cookies_from_id('equations_panel');
    read_panel_cookies_from_id('assignments_panel');
    read_panel_cookies_from_id('initial_panel');
    read_panel_cookies_from_id('parameters_panel');
    read_panel_cookies_from_id('functions_panel');
    read_panel_cookies_from_id('events_panel');
    read_panel_cookies_from_id('annotated_reactions_panel');
    read_panel_cookies_from_id('annotated_species_panel');
    
    if ($('plotGraphPanel').value == "on") {
//        rc.SetCurrentWidth2(cookieToArray('rc')[0]);
//        rc.SetCurrentHeight(cookieToArray('rc')[1]);
    };
    if ($('plotKineticsPanel').value == "on") {
        rc2.SetCurrentWidth2(cookieToArray('rc2')[0]);
        rc2.SetCurrentHeight(cookieToArray('rc2')[1]);
    };

}

function read_panel_cookies_from_id(id){
    try {
        $(id).style.display = readCookie(id);
        rtElement = rtHash[id];
        rtElement.SetCurrentWidth(cookieToArray(id + "_rt")[0]);
        rtElement.SetCurrentHeight(cookieToArray(id + "_rt")[1]);
    } 
    catch (err) {
    
    }    
}

function highlight_error(prefix){
    var panel = prefix + "_panel";
    var caption = prefix + "_caption";
    Effect.BlindDown(panel, {
        duration: 0.3
    });
    chevronExpand(prefix);
    Element.removeClassName(caption, "squareboxgradientcaption");
    $(caption).addClassName("squareboxgradientcaption2");
    new Effect.Highlight(panel, {
        startcolor: "#ff1111"
    });
}

function togglePanel(prefix){
    Effect.toggle(prefix + "_panel", "blind", {
        duration: 0.25
    });
    toggleChevron(prefix);
}

function save_new_version_extra_options(){
    var filename = $('new_version_filename_rb').value;
    var type = $('model_format').value;
    if (filename.endsWith(".dat") && type == 'sbml') {
        filename = filename.gsub("\.dat$", ".xml");
        $('new_version_filename_rb').value = filename;
    }
    
    if (filename.endsWith(".xml") && type == 'dat') {
        filename = filename.gsub("\.xml$", ".dat");
        $('new_version_filename_rb').value = filename;
    }
    
    RedBox.showInline('new_version_details');
    return false;
}

function toggleChevron(prefix){
    chevron = $(prefix + "_chevron");
    var expand = (chevron.src.indexOf("expand.gif") > 0);
    chevron.src = chevron.src.split(expand ? "expand.gif" : "collapse.gif").join(expand ? "collapse.gif" : "expand.gif");
}

function chevronExpand(prefix){
    chevron = $(prefix + "_chevron");
    expand = true;
    chevron.src = chevron.src.split(expand ? "expand.gif" : "collapse.gif").join(expand ? "collapse.gif" : "expand.gif");
}
