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

function updateInstitutionIds(){
    var institution_ids_element = $('project_institution_ids');
    var institution_ids = [];
    var checkbox_elements = document.getElementsByClassName('institution_checkbox');
    for(var i = 0; i < checkbox_elements.length ; i++){
        var checkbox = checkbox_elements[i];
        if (checkbox.checked){
            institution_ids.push(checkbox.value);
        }
    }

    institution_ids_element.setValue(institution_ids);
}

//project membership administration stuff
var previouslyRemoved = {}

function mark_group_membership_for_removal(person_id,institution_id,group_id) {
    var element_id = "#membership_"+person_id+"_"+institution_id;
    $j(element_id).remove();
    if ($j.isNumeric(group_id)) {
        var option = document.createElement("option");
        option.value = group_id;
        option.text = group_id;
        option.selected=true;
        $j("#group_memberships_to_remove").append(option);
        previouslyRemoved[person_id+"_"+institution_id]=group_id;
    }
}

function add_selected_people() {
    var people = determine_selected_people();

    $j.each(people, function (index, value) {
        var person_id = value["person_id"];
        var person_name = value["person_name"];
        var institution_id = $j("#institution_ids").val();
        var institution_title = $j("#institution_ids option:selected").text();
        var li_id = "membership_" + person_id+"_"+institution_id;
        if ($j("#"+li_id).length==0) {
            var group_id = previouslyRemoved[person_id+"_"+institution_id];
            if (group_id) {
                $j("#group_memberships_to_remove option[value="+group_id+"]").remove();
                var onclick = function () {
                    mark_group_membership_for_removal(person_id,institution_id,group_id);
                    return false;
                }
            }
            else {
                var dummy_id = guid();
                var json = JSON.stringify({person_id: person_id, institution_id: institution_id, institution_title: institution_title});
                var option = document.createElement('option');
                option.value=json;
                option.text=json;
                option.selected=true;
                $j("#people_and_institutions_to_add").append(option);
                var onclick = "'mark_group_membership_for_removal("+person_id+","+institution_id+",\"" + dummy_id + "\");";
                onclick = function() {
                    remove_from_people_to_add(person_id,institution_id);
                    mark_group_membership_for_removal(person_id,institution_id,dummy_id);
                    return false;
                }
            }

            var block = $j("#institution_block_" + institution_id);
            if (block.length == 0) {
                var ul = document.createElement('ul');
                ul.className = "institution_members";
                ul.id = 'institution_block_' + institution_id;
                var span = document.createElement('span');
                span.className="institution_label";
                span.id="institution_label_" + institution_id;
                span.innerHTML = institution_title;
                ul.appendChild(span);
                $j("#project_institutions").append(ul);
                block = $j("#institution_block_" + institution_id);
            }

            var li = document.createElement('li');
            li.id=li_id;
            li.className="institution_member";
            li.innerHTML = person_name+"&nbsp;";
            var a = document.createElement('a');
            var icon_span = document.createElement("span");
            icon_span.className='remove_member_icon';
            a.appendChild(icon_span);
            a.href="#";
            a.onclick=onclick;
            li.appendChild(a);

            block.append(li);
        }

    });

    autocompleters["person_autocompleter"].deleteAllTokens();

}

function remove_from_people_to_add(person_id, institution_id) {
    $j("#people_and_institutions_to_add > option").each(function (index, value) {
        var json = JSON.parse(value.value);
        if (json["person_id"] == person_id && json["institution_id"] == institution_id) {
            value.remove();
        }
    })
}

function determine_selected_people() {
    var people_ids = autocompleters["person_autocompleter"].getRecognizedSelectedIDs();
    var result = [];
    for (var i = 0; i < people_ids.length; i++) {
        id = parseInt(people_ids[i]);
        var name = autocompleters["person_autocompleter"].getValueFromJsonArray(autocompleters["person_autocompleter"].itemIDsToJsonArrayIDs([id])[0], 'name');
        result.push({person_id: id, person_name: name});
    }
    return result;
}


function setup_autocompleter(suggestion_list_json) {
    var suggestion_list = suggestion_list_json;
    var prepopulate_with = [];

    var person_autocompleter = new Autocompleter.LocalAdvanced(
        'person_autocompleter', 'person_autocomplete_input', 'person_autocomplete_display', 'person_autocomplete_populate', suggestion_list, prepopulate_with, {
            frequency: 0.1,
            updateElement: addAction,
            search_field: "name",
            hint_field: "email",
            id_field: "id",
            validation_type: "only_suggested"
        });
    var hidden_input = new HiddenInput('people_hidden_input', person_autocompleter);

    autocompleters["person_autocompleter"] = person_autocompleter;
}

