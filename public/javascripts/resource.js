function showResourceVersion(form) {
    var url=$('resource_versions').value;    
    location.href=url;
    form.submit;
}

// ***************  Resource Upload Validation  *****************

function validateSopFields(is_new_file) {
    // only make this test if that's a new SOP
    if(is_new_file) {
        if($('sop_data').value.length == 0 && $('sop_data_url').value.length == 0) {
            alert("Please specify the file to upload, or provide a URL.");
            $('sop_data').focus();
            return(false);
        }
    }

    // other tests are applicable to both editing and creating new SOP
    if($('sop_title').value.length == 0) {
        alert("Please specify the title for the SOP!");
        $('sop_title').focus();
        return(false);
    }

    // check if no tokens remain in the attributions autocompleter
    // (only do this if the fold with attributions is expanded)
    if($('attributions_fold_content').style.display == "block" &&
        autocompleters[attributions_autocompleter_id].getRecognizedSelectedIDs() != "")
        {
        alert('You didn\'t press "Add" link to add items in the attributions autocomplete field.');
        $('attributions_autocomplete_input').focus();
        return(false);
    }

    // filename and title set - can submit
    $('sop_submit_btn').disabled = true;
    $('sop_submit_btn').value = (is_new_file ? "Uploading and Saving..." : "Updating...");
    $('sop_submit_btn').form.submit();
    return(true);
}

function validateModelFields(is_new_file) {
    // only make this test if that's a new Model
    if(is_new_file) {
        if($('model_data').value.length == 0 && $('model_data_url').value.length == 0) {
            alert("Please specify the file to upload, or provide a URL.");
            $('model_data').focus();
            return(false);
        }
    }

    // other tests are applicable to both editing and creating new Model
    if($('model_title').value.length == 0) {
        alert("Please specify the title for the Model!");
        $('model_title').focus();
        return(false);
    }

    // check if no tokens remain in the attributions autocompleter
    // (only do this if the fold with attributions is expanded)
    if($('attributions_fold_content').style.display == "block" &&
        autocompleters[attributions_autocompleter_id].getRecognizedSelectedIDs() != "")
        {
        alert('You didn\'t press "Add" link to add items in the attributions autocomplete field.');
        $('attributions_autocomplete_input').focus();
        return(false);
    }

    // filename and title set - can submit
    $('model_submit_btn').disabled = true;
    $('model_submit_btn').value = (is_new_file ? "Uploading and Saving..." : "Updating...");
    $('model_submit_btn').form.submit();
    return(true);
}

function validateDataFileFields(is_new_file) {
    // only make this test if that's a new DataFile
    if(is_new_file) {
        if($('data_file_data').value.length == 0 && $('data_file_data_url').value.length == 0) {
            alert("Please specify the file to upload, or provide a URL");
            $('data_file_data').focus();
            return(false);
        }
    }

    // other tests are applicable to both editing and creating new Model
    if($('data_file_title').value.length == 0) {
        alert("Please specify the title for the Data file!");
        $('data_file_title').focus();
        return(false);
    }

    // check if no tokens remain in the attributions autocompleter
    // (only do this if the fold with attributions is expanded)
    if($('attributions_fold_content').style.display == "block" &&
        autocompleters[attributions_autocompleter_id].getRecognizedSelectedIDs() != "")
        {
        alert('You didn\'t press "Add" link to add items in the attributions autocomplete field.');
        $('attributions_autocomplete_input').focus();
        return(false);
    }

    // filename and title set - can submit
    $('data_file_submit_btn').disabled = true;
    $('data_file_submit_btn').value = (is_new_file ? "Uploading and Saving..." : "Updating...");
    $('data_file_submit_btn').form.submit();
    return(true);
}