//JS relating to the related-investigation selection form

var investigation_array=new Array();

function addInvestigation(title,id) {
    if(checkNotInList(id,investigation_array)) {
        investigation_array.push([title,id]);
    }
}

function addSelectedInvestigation() {
    selected_option_index=$("possible_investigations").selectedIndex;
    selected_option=$("possible_investigations").options[selected_option_index];
    title=selected_option.innerHTML;
    id=selected_option.value;

    i = $('possible_investigations').selectedIndex;
    selected_id = $('possible_investigations').options[i].value;
    if(selected_id != '0') {
        if(checkNotInList(id,investigation_array)) {
            addInvestigation(title,id);
            updateInvestigations();
        }
        else {
            alert('The following item had already been added:\n\n' +
                title);
        }
    }
}

function removeInvestigation(index) {
    investigation_array.splice(index, 1);

    // update the page
    updateInvestigations();
}

function updateInvestigations() {
    investigation_text='<ul class="related_asset_list">';
    type="investigation";
    investigation_ids=new Array();

    for (var i=0;i<investigation_array.length;i++) {
        investigation=investigation_array[i];
        title=investigation[0];
        id=investigation[1];
        titleText = '<span title="' + title + '">' + title.truncate(100) + '</span>';
        investigation_text += '<li>' + titleText
                //+ "&nbsp;&nbsp;<span style='color: #5F5F5F;'>(" + contributor + ")</span>"
            + '&nbsp;&nbsp;<small style="vertical-align: middle;">'
            + '[<a href="" onclick="javascript:removeInvestigation('+i+'); return(false);">remove</a>]</small></li>';
        investigation_ids.push(id);
    }

    investigation_text += '</ul>';

    // update the page
    if(investigation_array.length == 0) {
        $('investigation_to_list').innerHTML = '<span class="none_text">None</span>';
    }
    else {
        $('investigation_to_list').innerHTML = investigation_text;
    }

    clearList('investigation_ids');

    select=$('investigation_ids');
    for (i=0;i<investigation_ids.length;i++) {
        id=investigation_ids[i];
        o=document.createElement('option');
        o.value=id;
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
