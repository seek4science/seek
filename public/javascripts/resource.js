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

    if (!checkProjectExists("sop")) {
        return (false);
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

    if (!checkProjectExists("model")) {
        return (false);
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

    if (!checkProjectExists("data_file")) {
        return (false);
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
    clickLink($('preview_permission'));
}

function validatePresentationFields(is_new_file) {
    // only make this test if that's a new DataFile
    if(is_new_file) {
        if($('presentation_data').value.length == 0 && $('presentation_data_url').value.length == 0) {
            alert("Please specify the file to upload, or provide a URL");
            $('presentation_data').focus();
            return(false);
        }
    }

    // other tests are applicable to both editing and creating new Model
    if($('presentation_title').value.length == 0) {
        alert("Please specify the title for the presentation!");
        $('presentation_title').focus();
        return(false);
    }

    if (!checkProjectExists("presentation")) {
        return (false);
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
    $('presentation_submit_btn').disabled = true;
    $('presentation_submit_btn').value = (is_new_file ? "Uploading and Saving..." : "Updating...");
    $('presentation_submit_btn').form.submit();
    return(true);
}

function checkProjectExists(prefix) {
    el=prefix+"_project_ids";
    if ($F(el).length < 1) {
        alert("Please specify at least one project");
        return (false);       
    }
    return(true);
}

function clickLink(link) {
    var cancelled = false;

    if (document.createEvent) {
        var event = document.createEvent("MouseEvents");
        event.initMouseEvent("click", true, true, window,
            0, 0, 0, 0, 0,
            false, false, false, false,
            0, null);
        cancelled = !link.dispatchEvent(event);
    }
    else if (link.fireEvent) {
        cancelled = !link.fireEvent("onclick");
    }

    if (!cancelled) {
        window.location = link.href;
    }
}

function updateResource(is_new_file){
    // filename and title set - can submit
    $('data_file_submit_btn').disabled = true;
    $('data_file_submit_btn').value = (is_new_file ? "Uploading and Saving..." : "Updating...");
    $('data_file_submit_btn').form.submit();

    RedBox.close();
}