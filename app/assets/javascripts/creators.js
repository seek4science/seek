function updateCreatorSettings() {
    var html = '';
    var creators_arr = [];

    for(var i = 0; i < creators.length; i++) {
        var creator = creators[i];
        html += HandlebarsTemplates['creator'](creator);
        creators_arr.push([creator.name, creator.id]);
    }

    // update the page
    if(html.length == 0) {
        $j('#creators_list').html('<span class="subtle">No creators</span>');
    }
    else {
        $j('#creators_list').html(html);
    }

    // UPDATE THE FIELDS WHICH WILL BE SUBMITTED WITH THE PAGE
    $j('#creators').val(Object.toJSON(creators_arr));

    $j('#creators_list .delete').click(function () {
        var id = $j(this).data('objectId');
        for(var i = 0; i < creators.length; i++) {
            if(creators[i].id == id) {
                creators.splice(i, 1);
                break;
            }
        }
        // update the page
        updateCreatorSettings();
    });
}

function checkCreatorNotInList(creator) {
    for(var i = 0; i < creators.length; i++) {
        if (creators[i].id == creator.id)
            return false;
    }
    return true;
}

function addCreator(creator) {
    if(checkCreatorNotInList(creator)) {
        creators.push(creator);
        updateCreatorSettings();
    }
    else {
        alert('The following creator was not added (already in the list of creators):\n\n' + creator.name);
    }
}

function updateInstitutionList(data, project_name){
    data = data.evalJSON(true);
    var element = $j('#adv_creator_select_institutions')[0];
    var spinner = $j('#adv_creator_select_project_spinner')[0];
    element.options.length = "";
    element.options[0] = new Option('All members of ' + project_name, 0);
    var next_index_to_use = 1;
    for (var i = 0; i < data.institution_list.length; i++) {
        element.options[next_index_to_use] = new Option('Members of ' + project_name + ' @ ' + data.institution_list[i][0], data.institution_list[i][1]);
        next_index_to_use++;
    }
    spinner.hide();
    element.show();
    $j('#adv_creator_select_add').show();
}

function addPeopleToList(data){
    data = data.evalJSON(true);
    for (var i = 0; i < data.people_list.length; i++) {
        addCreator({name: data.people_list[i][0], email: data.people_list[i][1], id: data.people_list[i][2]});
    }
    $j('#adv_creator_select_spinner').hide();
}

$j(function() {
    $j('#creator-typeahead').on('itemAdded', function (event) {
        addCreator(event.item);
        $j(this).tagsinput('removeAll'); // clear the input
    });
});
