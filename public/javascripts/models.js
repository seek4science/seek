function model_type_selection_changed() {
    var selected=$('model_model_type_id');
    if (selected.value)
    {
        $('edit_model_type_icon').show();
        var text=selected.options[selected.selectedIndex].text        
        $('updated_model_type').value=text;
        $('updated_model_type_id').value=selected.value;
        $('update_model_type_button').disabled=false;
    }
    else
    {
        $('edit_model_type_icon').hide();
        $('updated_model_type').value="";
        $('updated_model_type_id').value="";
        $('update_model_type_button').disabled=true;
    }
}

function model_format_selection_changed() {
    var selected=$('model_model_format_id');
    if (selected.value)
    {
        $('edit_model_format_icon').show();
        var text=selected.options[selected.selectedIndex].text
        $('updated_model_format').value=text;
        $('updated_model_format_id').value=selected.value;
        $('update_model_format_button').disabled=false;
    }
    else
    {
        $('edit_model_format_icon').hide();
        $('updated_model_format').value="";
        $('updated_model_format_id').value="";
        $('update_model_format_button').disabled=true;
    }
}