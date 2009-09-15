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