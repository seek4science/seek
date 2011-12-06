// ***************  Attributions  *****************


function updateAttributionSettings() {
    // iterate through all attributions and build the "shared with" list;
    // in the meanwhile also assemble a minimized version of the array that
    // could be posted with the form (this won't have item titles in it)

    var attributed_to = '';
    var attributed_to_arr = new Array();

    for(var i = 0; i < attribution_settings.length; i++) {
        attr_type = attribution_settings[i][0];
        attr_title = attribution_settings[i][1];
        attr_id = attribution_settings[i][2];
        attr_contributor = autocompleters[attributions_autocompleter_id].getValueFromJsonArray(autocompleters[attributions_autocompleter_id].itemIDsToJsonArrayIDs([attr_id])[0], 'contributor');

        attributed_to += '<b>' + attr_type + '</b>: ' + attr_title
        + "&nbsp;&nbsp;<span style='color: #5F5F5F;'>(" + attr_contributor + ")</span>"
        + '&nbsp;&nbsp;<small style="vertical-align: middle;">'
        + '[<a href="" onclick="javascript:deleteAttribution(\''+ attr_type +'\', '+ attr_id +'); return(false);">remove</a>]</small><br/>';

        attributed_to_arr.push([attr_type, attr_id]);
    }


    // remove the last line break
    if(attributed_to.length > 0) {
        attributed_to = attributed_to.slice(0,-5);
    }


    // update the page
    if(attributed_to.length == 0) {
        $('attributed_to_list').innerHTML = '<span class="none_text">No attributions</span>';
    }
    else {
        $('attributed_to_list').innerHTML = attributed_to;
    }


    // UPDATE THE FIELDS WHICH WILL BE SUBMITTED WITH THE PAGE
    $('attributions').value = Object.toJSON(attributed_to_arr);
}


function checkAttributionNotInList(attributable_type, attributable_id) {
    rtn = true;

    for(var i = 0; i < attribution_settings.length; i++)
        if(attribution_settings[i][0] == attributable_type && attribution_settings[i][2] == attributable_id) {
            rtn = false;
            break;
        }

    return(rtn);
}


// adds a contributor to "attributed to" list and updates the displayed list
function addAttribution(attributable_type, attributable_title, attributable_id) {
    if(checkAttributionNotInList(attributable_type, attributable_id)) {
        // add current values into the associative array of permissions:
        // first index is the category of contributor type of the permission, the second - consecutive
        // number of occurrences of permissions for such type of contributor
        attribution_settings.push([attributable_type, attributable_title, attributable_id]);

        // update visible page
        updateAttributionSettings();
    }
    else {
        alert('The following entity was not added (already in the list of attributions):\n\n' +
            attributable_type + ': ' + attributable_title);
    }
}


// removes attribution from "attributed to" list and updates the displayed list
function deleteAttribution(attributable_type, attributable_id) {
    // remove the actual record for the attribution
    for(var i = 0; i < attribution_settings.length; i++)
        if(attribution_settings[i][0] == attributable_type && attribution_settings[i][2] == attributable_id) {
            attribution_settings.splice(i, 1);
            break;
        }

    // update the page
    updateAttributionSettings();
}


function addAttributions() {
    var selIDs = autocompleters[attributions_autocompleter_id].getRecognizedSelectedIDs();

    if(selIDs == "") {
        // no attributions to add
        alert("Please choose some assets to add attributions to!");
        return(false);
    }
    else {
        // some attributions to add - known that don't have duplicates
        // within the new list, but some entries in the new list
        // may replicate those in the main attribution list: this
        // will be checked by addAttribution()

        for(var i = 0; i < selIDs.length; i++) {
            id = parseInt(selIDs[i]);
            title = autocompleters[attributions_autocompleter_id].getValueFromJsonArray(autocompleters[attributions_autocompleter_id].itemIDsToJsonArrayIDs([id])[0], 'title');
            type = autocompleters[attributions_autocompleter_id].getValueFromJsonArray(autocompleters[attributions_autocompleter_id].itemIDsToJsonArrayIDs([id])[0], 'type');
            addAttribution(type, title, id);
        }

        // remove all tokens from autocomplete text box
        autocompleters[attributions_autocompleter_id].deleteAllTokens();

        return(true);
    }
}