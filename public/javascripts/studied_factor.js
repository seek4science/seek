var autocompleters = new Array();

function additionalFieldForItem(form_id, fs_or_ec_id){
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
        fade(fs_or_ec_id + 'growth_medium_or_buffer_description')
        appear(fs_or_ec_id + 'substance_condition_factor')
    }
    else if (option_select.text == 'growth medium' || option_select.text == 'buffer'){
        fade(fs_or_ec_id + 'substance_condition_factor')
        appear(fs_or_ec_id + 'growth_medium_or_buffer_description')
    }
    else{
        fade(fs_or_ec_id + 'substance_condition_factor')
        fade(fs_or_ec_id + 'growth_medium_or_buffer_description')
    }
}

function appear(element_id){
   Effect.Appear(element_id, { duration: 0.5 });
}

function fade(element_id){
   Effect.Fade(element_id, { duration: 0.25 });
}
