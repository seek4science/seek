function showResourceVersion(form) {
    var url=$('resource_versions').value;    
    location.href=url;
    form.submit;
}

// ***************  Resource Upload Validation  *****************

function validateResourceFields(is_new_file, resource_name) {

    // only make this test if that's a new SOP
    if(is_new_file) {
        if($(resource_name + '_data').value.length == 0 && $(resource_name + '_data_url').value.length == 0) {
            alert("Please specify the file to upload, or provide a URL.");
            $(resource_name + '_data').focus();
            return(false);
        }
    }

    // other tests are applicable to both editing and creating new SOP
    if($(resource_name + '_title').value.length == 0) {
        alert("Please specify the title for the !");
        $(resource_name + '_title').focus();
        return(false);
    }

    if (!checkProjectExists(resource_name)) {
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

function createOrUpdateResource(is_new_file, resource_name){
    // filename and title set - can submit
    $(resource_name + '_submit_btn').disabled = true;
    $(resource_name + '_submit_btn').value = (is_new_file=='true' ? "Creating..." : "Updating...");
    $(resource_name + '_submit_btn').form.submit();

    RedBox.close();
}