// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults


var tabber_ids = new Array();
var tabberOptions = {'onLoad':function() {
    displayTabs();
}};

function displayTabs() {

    for (var i = 0; i < tabber_ids.length; i++) {
        var tabber_id = tabber_ids[i];
        var spinner = tabber_id + "_spinner";
        $(spinner).hide();
        Effect.Appear(tabber_id, {duration : 0.5});
    }
}


function trimSpaces(str) {
    while ((str.length > 0) && (str.charAt(0) == ' '))
        str = str.substring(1);
    while ((str.length > 0) && (str.charAt(str.length - 1) == ' '))
        str = str.substring(0, str.length - 1);
    return str;
}

function addToolListTag(tag_id) {
    tools_autocompleter = autocompleters['tools_autocompleter']
    var index = tools_autocompleter.itemIDsToJsonArrayIDs([tag_id])[0];
    var item = new Element('a', {
        'value': index
    });
    tools_autocompleter.addContactToList(item);
}

function addExpertiseListTag(tag_id) {
    expertise_autocompleter = autocompleters['expertise_autocompleter']
    var index = expertise_autocompleter.itemIDsToJsonArrayIDs([tag_id])[0];
    var item = new Element('a', {
        'value': index
    });
    expertise_autocompleter.addContactToList(item);
}

function addOrganismListTag(tag_id) {

    organism_autocompleter = autocompleters['organism_autocompleter']
    var index = organism_autocompleter.itemIDsToJsonArrayIDs([tag_id])[0];
    var item = new Element('a', {
        'value': index
    });
    organism_autocompleter.addContactToList(item);
}


function checkNotInList(id, list) {
    rtn = true;

    for (var i = 0; i < list.length; i++)
        if (list[i][1] == id) {
            rtn = false;
            break;
        }

    return(rtn);
}

function clearList(name) {
    select = $(name)
    while (select.length > 0) {
        select.remove(select.options[0])
    }
}
