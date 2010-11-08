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

function togglePanel(panel_name){
    Effect.toggle(panel_name + "_panel", "blind", {
        duration: 0.25
    });
    chevron = $(panel_name + "_chevron")
    var expand = (chevron.src.indexOf("expand.gif") > 0);
    chevron.src = chevron.src.split(expand ? "expand.gif" : "collapse.gif").join(expand ? "collapse.gif" : "expand.gif");
}
