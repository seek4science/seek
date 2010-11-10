function check_clicked(){
    $('check_button').value = "Submitting ...";
    $('check_button').disabled = true;
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
	$('new_version_comments').value=$('new_version_comments_rb').value;
	$('new_version_filename').value=$('new_version_filename_rb').value;
	$('new_version_options').hide();
	$('new_version_waiting').show();
    $('new_version_button').value = "Submitting ...";
    $('new_version_button').disabled = true;
    $('form').following_action.value = "save_new_version";
    $('form').saved_model_format.value = $('model_format').value;
    $('form').submit();
}

function highlight_error(prefix) {
	var panel=prefix+"_panel";
	var caption=prefix+"_caption";
	Effect.BlindDown(panel,{duration:0.3});
	chevronExpand(prefix)				
	Element.removeClassName(caption,"squareboxgradientcaption");	
	$(caption).addClassName("squareboxgradientcaption2");
	new Effect.Highlight(panel,{startcolor:"#ff1111"});
}

function togglePanel(prefix){
    Effect.toggle(prefix + "_panel", "blind", {
        duration: 0.25
    });    
	toggleChevron(prefix);
}

function toggleChevron(prefix) {
	chevron = $(prefix + "_chevron");
    var expand = (chevron.src.indexOf("expand.gif") > 0);
    chevron.src = chevron.src.split(expand ? "expand.gif" : "collapse.gif").join(expand ? "collapse.gif" : "expand.gif");
}

function chevronExpand(prefix) {
	chevron = $(prefix + "_chevron");
	expand=true;
	chevron.src = chevron.src.split(expand ? "expand.gif" : "collapse.gif").join(expand ? "collapse.gif" : "expand.gif");
}
