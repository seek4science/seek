var autocompleters = new Array();

function showOrHideSubstanceTextField(form_id){
    var elements =  $(form_id).getElements();
    var item;
    var substance_autocomplete;
    for (var i=0;i<elements.length;i++)
    {
      var id = elements[i].id;
      if (id.match('measured_item_id'))
        item = elements[i];
      if (id.match('autocomplete_input'))
        substance_autocomplete = elements[i];
    }

    //check if the selected item is concentration
    var selectedIndex = item.selectedIndex;
    var option_select = item.options[selectedIndex];

    if (option_select.text == 'concentration'){
        substance_autocomplete.disabled = false;

    }else{
        //clear all the substances when disable
        var autocompleter_id = substance_autocomplete.id.replace('autocomplete_input', '');
        autocompleter_id = autocompleter_id.concat('autocompleter');
        autocompleters[autocompleter_id].deleteAllTokens();
        substance_autocomplete.disabled = true;
    }
}
