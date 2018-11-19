var autocompleters = [];

function additionalFieldForItem(form_id, fs_or_ec_id){
    var elements =  $(form_id).getElements();
    var item;
    for (var i=0;i<elements.length;i++)
    {
        var id = elements[i].id;
        if (id.match('measured_item_id'))
            item = elements[i];
    }

    //check if the selected item is concentration
    var selectedIndex = item.selectedIndex;
    var option_select = item.options[selectedIndex];

    if (option_select.text == 'concentration'){
        $j('#' + fs_or_ec_id + 'growth_medium_or_buffer_description').fadeOut();
        $j('#' + fs_or_ec_id + 'substance_condition_factor').fadeIn();
    }
    else if (option_select.text == 'growth medium' || option_select.text == 'buffer'){
        $j('#' + fs_or_ec_id + 'substance_condition_factor').fadeOut();
        $j('#' + fs_or_ec_id + 'growth_medium_or_buffer_description').fadeIn();
    }
    else{
        $j('#' + fs_or_ec_id + 'substance_condition_factor').fadeOut();
        $j('#' + fs_or_ec_id + 'growth_medium_or_buffer_description').fadeOut();
    }
}
