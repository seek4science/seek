//JS relating to the related-publication selection form

var publication_array=new Array();

function addPublication(title,id,relationshipType) {
    publication_array.push([title,id,relationshipType]);
}

function addSelectedPublication() {
    selected_option_index=$("possible_publications").selectedIndex;
    selected_option=$("possible_publications").options[selected_option_index];
    title=selected_option.innerHTML;
    id=selected_option.value;
    if ($("publication_relationship_type")) {
        relationshipType = $("publication_relationship_type").options[$("publication_relationship_type").selectedIndex].text;
    }
    else
    {
        relationshipType="None"
    }
    if (id != "0"){
        if(checkNotInList(id,publication_array)) {
            addPublication(title,id,relationshipType);
            updatePublications();
        }
        else {
            alert('The following publication has already been added:\n\n' +
                title);
        }
    }
}

function removePublication(index) {
    publication_array.splice(index, 1);
    // update the page
    updatePublications();
}

function updatePublications() {
    publication_text='<ul class="related_asset_list">'
    
    for (var i=0;i<publication_array.length;i++) {        
        publication=publication_array[i];
        title=publication[0];
        id=publication[1];
        relationshipType = 'None'; //publication[2]; This can be used to specify how the publication is related (not used atm)
        relationshipText = (relationshipType == 'None') ? '' : ' <span class="assay_item_sup_info">(' + relationshipType + ')</span>';
        titleText = '<span title="' + title + '">' + title.truncate(100) + '</span>';
        publication_text += '<li>' + titleText + relationshipText +
        '&nbsp;&nbsp;<small style="vertical-align: middle;">'
        + '[<a href="" onclick="javascript:removePublication('+i+'); return(false);">remove</a>]</small></li>';
    }
    
    publication_text += '</ul>';

    // update the page
    if(publication_array.length == 0) {
        $('publication_to_list').innerHTML = '<span class="none_text">None</span>';
    }
    else {
        $('publication_to_list').innerHTML = publication_text;
    }

    clearList('related_publication_ids');

    select=$('related_publication_ids');
    for (i=0;i<publication_array.length;i++) {
        id=publication_array[i][1];
        relationshipType=publication_array[i][2];
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