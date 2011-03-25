var assays_array = new Array();
var id_rel_array = new Array();
//Assays for data_files
function check_show_add_assay() {
    i = $('possible_assays').selectedIndex;
    selected_id = $('possible_assays').options[i].value;
    if (selected_id == '0') {
        $('add_assay_link').hide();
    }
    else {
        $('add_assay_link').show();
    }
}


function addAssay(title,id,relationshipType) {
    assays_array.push([title,id,relationshipType]);
}

function addSelectedAssay() {
    selected_option_index=$("possible_assays").selectedIndex;
    selected_option=$("possible_assays").options[selected_option_index];
    title=selected_option.text;
    id=selected_option.value;
    if ($("assay_relationship_type")) {
        relationshipType = $("assay_relationship_type").options[$("assay_relationship_type").selectedIndex].text;
    }
    else
    {
        relationshipType="None"
    }

    if(checkNotInList(id,assays_array)) {
        addAssay(title,id,relationshipType);
        updateAssays();
    }
    else {
        alert('The following Data file had already been added:\n\n' +
            title);
    }
}

function updateAssays() {
    assay_text = '<ul class="related_asset_list">'
    for (var i=0;i<assays_array.length;i++) {
        assay=assays_array[i];
        title=assay[0];
        id=assay[1];
        relationshipType = assay[2];
        relationshipText = (relationshipType == 'None') ? '' : ' <span class="assay_item_sup_info">(' + relationshipType + ')</span>';
        titleText = '<span title="' + title + '">' + title.truncate(100) + '</span>';
        assay_text += '<li>' + titleText + relationshipText +
        '&nbsp;&nbsp;&nbsp;<small style="vertical-align: middle;">'
        + '[<a href="" onclick="javascript:removeAssay('+i+'); return(false);">remove</a>]</small></li>';
    }
    assay_text += '</ul>';

    // update the page
    if (assays_array.length == 0) {
        $('assay_to_list').innerHTML = '<span class="none_text">No assays</span>';
    }
    else {
        $('assay_to_list').innerHTML = assay_text;
    }

    clearList('assay_ids');
    select=$('assay_ids');
    for (i=0;i<assays_array.length;i++) {
        id=assays_array[i][1];
        relationshipType=assays_array[i][2];
        o=document.createElement('option');
        o.value=id + "," + relationshipType;
        o.text=id;
        o.selected=true;
        try {
            select.add(o); //for older IE version
        }
        catch (ex) {
            select.add(o,null);
        }
    }
}

function removeAssay(index) {
    assays_array.splice(index, 1);
    // update the page
    updateAssays();
}