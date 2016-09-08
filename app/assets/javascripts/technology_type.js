function validateTechnologyTypeRequiredFields(submit_button_id) {
    if ($('technolgoy_type_title').value.length == 0) {
        alert("Please specify the title!");
        $('technology_type_title').focus();
        return(false);
    }
    else {
        $(submit_button_id).disabled = true;
        $(submit_button_id).value = "Creating...";
        $(submit_button_id).form.submit();
    }
}