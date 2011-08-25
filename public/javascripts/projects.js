var organisms=new Array();
var roles = new Array();


function addSelectedOrganism() {
    selected_option_index=$("possible_organisms").selectedIndex
    selected_option=$("possible_organisms").options[selected_option_index]
    title=selected_option.text
    id=selected_option.value

    if(checkNotInList(id,organisms)) {
        addOrganism(title,id);
        updateOrganisms();
    }
    else {
        alert('The organism had already been added:\n\n' +
            title);
    }
}

function removeOrganism(id) {

    for(var i = 0; i < organisms.length; i++)
        if(organisms[i][1] == id) {
            organisms.splice(i, 1);
            break;
        }

    // update the page
    updateOrganisms();
}

function updateOrganisms() {
    organism_text=''
    type="Organism"
    organism_ids=new Array();

    for (var i=0;i<organisms.length;i++) {
        organism=organisms[i]
        title=organism[0]
        id=organism[1]
        organism_text += '<b>' + type + '</b>: ' + title
        //+ "&nbsp;&nbsp;<span style='color: #5F5F5F;'>(" + contributor + ")</span>"
        + '&nbsp;&nbsp;<small style="vertical-align: middle;">'
        + '[<a href="" onclick="javascript:removeOrganism('+id+'); return(false);">remove</a>]</small><br/>';
        organism_ids.push(id)
    }

    // remove the last line break
    if(organism_text.length > 0) {
        organism_text = organism_text.slice(0,-5);
    }

    // update the page
    if(organism_text.length == 0) {
        $('organism_to_list').innerHTML = '<span class="none_text">No organisms</span>';
    }
    else {
        $('organism_to_list').innerHTML = organism_text;
    }

    clearList('project_organism_ids');

    select=$('project_organism_ids')
    for (i=0;i<organism_ids.length;i++) {
        id=organism_ids[i]
        o=document.createElement('option')
        o.value=id
        o.text=id
        o.selected=true
        try {
            select.add(o); //for older IE version
        }
        catch (ex) {
            select.add(o,null);
        }
    }
}

function addOrganism(title,id) {
    organisms.push([title,id])
}

