//JS relating to the related-study selection form

var study_array=new Array();

function addStudy(title,id) {
    if(checkNotInList(id,study_array)) {
        study_array.push([title,id]);
    }
}

function addSelectedStudy() {
    selected_option_index=$("possible_studies").selectedIndex;
    selected_option=$("possible_studies").options[selected_option_index];
    title=selected_option.innerHTML;
    id=selected_option.value;

    i = $('possible_studies').selectedIndex;
    selected_id = $('possible_studies').options[i].value;
    if(selected_id != '0') {
        if(checkNotInList(id,study_array)) {
            addStudy(title,id);
            updateStudies();
        }
        else {
            alert('The following item had already been added:\n\n' +
                title);
        }
    }
}

function removeStudy(index) {
    study_array.splice(index, 1);

    // update the page
    updateStudies();
}

function updateStudies() {
    study_text='<ul class="related_asset_list">';
    type="study";
    study_ids=new Array();

    for (var i=0;i<study_array.length;i++) {
        study=study_array[i];
        title=study[0];
        id=study[1];
        titleText = '<span title="' + title + '">' + title.truncate(100) + '</span>';
        study_text += '<li>' + titleText
                //+ "&nbsp;&nbsp;<span style='color: #5F5F5F;'>(" + contributor + ")</span>"
            + '&nbsp;&nbsp;<small style="vertical-align: middle;">'
            + '[<a href="" onclick="javascript:removeStudy('+i+'); return(false);">remove</a>]</small></li>';
        study_ids.push(id);
    }

    study_text += '</ul>';

    // update the page
    if(study_array.length == 0) {
        $('study_to_list').innerHTML = '<span class="none_text">None</span>';
    }
    else {
        $('study_to_list').innerHTML = study_text;
    }

    clearList('study_ids');

    select=$('study_ids');
    for (i=0;i<study_ids.length;i++) {
        id=study_ids[i];
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
