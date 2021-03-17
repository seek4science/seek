function updateCreatorSettings() {
    var html = '';
    var creators_arr = [''];

    for(var i = 0; i < creators.length; i++) {
        var creator = creators[i];
        html += HandlebarsTemplates['creator']({ creator: creator, prefix: resourceType });
        creators_arr.push([creator.name, creator.id]);
    }

    // update the page
    if(html.length == 0) {
        $j('#creators_list').html('<li class="association-list-item"><span class="none_text">No creators</span></li>');
    }
    else {
        $j('#creators_list').html(html);
    }

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

$j(function() {
    $j('#creator-typeahead').on('itemAdded', function (event) {
        addCreator(event.item);
        $j(this).tagsinput('removeAll'); // clear the input
    });
});
