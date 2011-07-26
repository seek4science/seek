var autocompleters = new Array();

function addListTag(name,tag_id) {
    autocompleter = autocompleters[name+'_autocompleter'];
    var index = autocompleter.itemIDsToJsonArrayIDs([tag_id])[0];
    var item = new Element('a', {
        'value': index
    });
    autocompleter.addContactToList(item);

}

//Add the last tag entered onto the list when the element becomes unfocused.
//Code taken from the onKeyPress method of autocompleter_advanced.js.
function addLastTag(autocompleter_id){
    var autocompleter = autocompleters[autocompleter_id];
    var unrecognized_item = autocompleter.element.value.strip().sub(',', '');
    if (unrecognized_item.length > 0 && autocompleter.validate_item(unrecognized_item)) {
      autocompleter.addUnrecognizedItemToList(unrecognized_item);
      autocompleter.element.value = "";
      autocompleter.set_input_size();
    }
    return false;
  }

