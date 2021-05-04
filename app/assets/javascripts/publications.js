var human_diseases=new Array();

function addSelectedHumanDisease() {
    selected_option_index=$("possible_human_diseases").selectedIndex;
    selected_option=$("possible_human_diseases").options[selected_option_index];
    title=selected_option.text;
    id=selected_option.value;

    if(checkNotInList(id,human_diseases)) {
        addHumanDisease(title,id);
        updateHumanDiseases();
    }
    else {
        alert('The human disease has already been added:\n\n' +
            title);
    }
}

function removeHumanDisease(id) {

    for(var i = 0; i < human_diseases.length; i++)
        if(human_diseases[i][1] == id) {
            human_diseases.splice(i, 1);
            break;
        }

    // update the page
    updateHumanDiseases();
}

function updateHumanDiseases() {
    human_disease_text='';
    type="Human Disease";
    human_disease_ids=new Array();

    for (var i=0;i<human_diseases.length;i++) {
        human_disease=human_diseases[i];
        title=human_disease[0];
        id=human_disease[1];
        human_disease_text += '<b>' + type + '</b>: ' + title
        //+ "&nbsp;&nbsp;<span style='color: #5F5F5F;'>(" + contributor + ")</span>"
        + '&nbsp;&nbsp;<small style="vertical-align: middle;">'
        + '[<a href="" onclick="javascript:removeHumanDisease('+id+'); return(false);">remove</a>]</small><br/>';
        human_disease_ids.push(id);
    }

    // remove the last line break
    if(human_disease_text.length > 0) {
        human_disease_text = human_disease_text.slice(0,-5);
    }

    // update the page
    if(human_disease_text.length == 0) {
        $('human_disease_to_list').innerHTML = '<span class="none_text">No human diseases</span>';
    }
    else {
        $('human_disease_to_list').innerHTML = human_disease_text;
    }

    clearList('publication_human_disease_ids');

    select=$('publication_human_disease_ids');
    for (i=0;i<human_disease_ids.length;i++) {
        id=human_disease_ids[i];
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

function addHumanDisease(title,id) {
    human_diseases.push([title,id]);
}
