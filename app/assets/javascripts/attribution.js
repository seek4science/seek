// ***************  Attributions  *****************

function updateAttributionSettings() {
    // iterate through all attributions and build the "shared with" list;
    // in the meanwhile also assemble a minimized version of the array that
    // could be posted with the form (this won't have item titles in it)

    var html = '';
    var attributed_to_arr = [];

    for(var i = 0; i < attributions.length; i++) {
        var attribution = attributions[i];
        html += HandlebarsTemplates['attribution'](attribution);
        attributed_to_arr.push([attribution.type, attribution.id]);
    }

    // update the page
    if(html.length == 0) {
        $j('#attributed_to_list').html('<li class="association-list-item"><span class="none_text">No attributions</span></li>');
    }
    else {
        $j('#attributed_to_list').html(html);
    }

    // UPDATE THE FIELDS WHICH WILL BE SUBMITTED WITH THE PAGE
    $j('#attributions').val(JSON.stringify(attributed_to_arr));

    $j('#attributed_to_list .delete').click(function () {
        var type = $j(this).data('objectType');
        var id = $j(this).data('objectId');
        for(var i = 0; i < attributions.length; i++) {
            if(attributions[i].type == type && attributions[i].id == id) {
                attributions.splice(i, 1);
                break;
            }
        }
        // update the page
        updateAttributionSettings();
    });
}

function checkAttributionNotInList(attributable) {
    for(var i = 0; i < attributions.length; i++) {
        var existingAttribution = attributions[i];
        if (existingAttribution.id == attributable.id && existingAttribution.type == attributable.type) {
            return false;
        }
    }
    return true;
}

$j(function() {
    $j('select#attribution-typeahead').on('select2:select', function (event) {
        var attributable = event.params.data;
        if(checkAttributionNotInList(attributable)) {
            attributions.push(attributable);
            updateAttributionSettings();
        }
        else {
            alert('The following entity was not added (already in the list of attributions):\n\n' +
            attributable.type + ': ' + attributable.text);
        }
        $j('select#attribution-typeahead').val([]).change(); // clear the input
    });
});
