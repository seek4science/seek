var model_formats_for_deletion = new Array();
var model_types_for_deletion = new Array();

function inList(item,list) {
    for (i=0;i<list.length;i++) {
        if (list[i]==item) return true;
    }
    return false;
}
function model_type_selection_changed() {
    var selected=$('model_model_type_id');
    $('selected_model_type_id').value=selected.value
    if (selected.value)
    {        
        $('edit_model_type_icon').show();
        if (inList(selected.value,model_types_for_deletion)) {
            $('delete_model_type_icon').show();
        }
        else {
            $('delete_model_type_icon').hide();
        }
        var text=selected.options[selected.selectedIndex].text        
        $('updated_model_type').value=text;
        $('updated_model_type_id').value=selected.value;
        $('update_model_type_button').disabled=false;
    }
    else
    {
        $('delete_model_type_icon').hide();
        $('edit_model_type_icon').hide();
        $('updated_model_type').value="";
        $('updated_model_type_id').value="";
        $('update_model_type_button').disabled=true;
    }
}

function model_format_selection_changed() {
    var selected=$('model_model_format_id');
    $('selected_model_format_id').value=selected.value
    if (selected.value)
    {
        $('edit_model_format_icon').show();
        if (inList(selected.value,model_formats_for_deletion)) {
            $('delete_model_format_icon').show();
        }
        else {
            $('delete_model_format_icon').hide();
        }
        var text=selected.options[selected.selectedIndex].text
        $('updated_model_format').value=text;
        $('updated_model_format_id').value=selected.value;
        $('update_model_format_button').disabled=false;
    }
    else
    {
        $('edit_model_format_icon').hide();
        $('delete_model_format_icon').hide();
        $('updated_model_format').value="";
        $('updated_model_format_id').value="";
        $('update_model_format_button').disabled=true;
    }
}