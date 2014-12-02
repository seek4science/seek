function possibilities_selection_changed() {
    if ($F('possible_scale_ids') == 0) {
        $('add_to_scale_ids_link').hide();
        $('additional_scale_details').hide();
    }
    else {
        $('add_to_scale_ids_link').show();
        $('additional_scale_details').show();
    }
}

function addSelectedToFancy2(multiselect, value) {
    value = {scale_id: value,
        param: $('choose_parameter_for_scale_id').value,
        unit: $('choose_unit_for_scale_id').value

    }
    if (!scale_and_params_selected(value)) {
        $(multiselect).setValue($F(multiselect).concat(value.scale_id));
        updateScaleAndParamsList(value);
        updateFancyMultiselect2(multiselect);
    } else {
        alert('Item already exists!');
    }
}

function scale_and_params_selected(json) {
    var found=false;
    $('scale_ids_and_params').select("option:selected").each(function(opt){
        var json2=JSON.parse(opt.value);
        console.log(json);
        console.log(json2);
        if (!found) {
            found = (json.scale_id == json2.scale_id && json.param==json2.param);
        }
    });
    return found;

}

function updateScaleAndParamsList(value) {
    var opt = document.createElement('option');
    opt.value=JSON.stringify(value);
    opt.innerHTML=JSON.stringify(value);
    opt.selected=true;
    $('scale_ids_and_params').appendChild(opt);
}

function updateFancyMultiselect2(multiselect) {
    multiselect = $(multiselect);
    var display_area = $(multiselect.id + '_display_area');

    var selected_options = multiselect.childElements().select(function(c){return c.selected});
    if(selected_options.length > 0) {
        display_area.innerHTML = '<ul class="related_asset_list"></ul>'
        var list = display_area.select('ul')[0];
        selected_options.each(function(opt){
            insertFancyListItem2(multiselect, list, opt);
        });
    } else {
        display_area.innerHTML = '<span class="none_text">None</span>';
    }
    multiselect.fire('fancySelect:update');
}

function insertFancyListItem2(multiselect, displaylist, option) {
    var json_list = fetchJsonForScale(option.value);
    for (i=0; i<json_list.length;i++) {
        json = json_list[i];
        var text = option.text;
        text += " (param:"+json.param+", unit:"+json.unit+")";
        var title_span = '<span title="' + text.escapeHTML() + '">' + text.truncate(100).escapeHTML() + '</span>';
        var remove_link = '<a href="" onclick="javascript:removeFromFancy2(';
        remove_link += "'" + $(multiselect).id + "','";
        remove_link += option.value + "','"+json.param+"'";
        remove_link += '); return(false);">remove</a>';
        displaylist.insert('<li>' + title_span +'&nbsp;&nbsp;<small style="vertical-align: middle;">[' + remove_link + ']</small></li>');
    }
}

function fetchJsonForScale(scale_id) {

    var result=new Array();
    var options = $('scale_ids_and_params').childElements().select(function(c){return c.selected});
    options.each(function(opt) {

        var json = JSON.parse(opt.value);
        if (json.scale_id == scale_id.toString()) {
            result.push(json);
        }

    });
    return result;
}

function removeFromFancy2(multiselect, value,param) {

    console.log(value);
    console.log(param);
    $('scale_ids_and_params').select("option:selected").each(function(opt){
        var item=JSON.parse(opt.value)

        if (item.scale_id == value && item.param==param) {
            console.log(opt.value);
            opt.remove();
        }
    });
    var json_list = fetchJsonForScale(value);
    if (json_list.length==0) {
        $(multiselect).setValue($F(multiselect).without(value));
    }
    updateFancyMultiselect2(multiselect);

}