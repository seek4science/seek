var disciplines=new Array();
var roles = new Array();

function addSelectedDiscipline() {
    selected_option_index=$("possible_disciplines").selectedIndex
    selected_option=$("possible_disciplines").options[selected_option_index]
    title=selected_option.text    
    id=selected_option.value

    if(checkNotInList(id,disciplines)) {
        addDiscipline(title,id);
        updateDisciplines();
    }
    else {
        alert('The following discipline had already been added:\n\n' +
            title);
    }
}

function removeDiscipline(id) {
    
    for(var i = 0; i < disciplines.length; i++)
        if(disciplines[i][1] == id) {
            disciplines.splice(i, 1);
            break;
        }

    // update the page
    updateDisciplines();
}

function updateDisciplines() {
    discipline_text=''
    type="Discipline"
    discipline_ids=new Array();

    for (var i=0;i<disciplines.length;i++) {
        discipline=disciplines[i]
        title=discipline[0]
        id=discipline[1]        
        discipline_text += '<b>' + type + '</b>: ' + title
        //+ "&nbsp;&nbsp;<span style='color: #5F5F5F;'>(" + contributor + ")</span>"
        + '&nbsp;&nbsp;<small style="vertical-align: middle;">'
        + '[<a href="" onclick="javascript:removeDiscipline('+id+'); return(false);">remove</a>]</small><br/>';
        discipline_ids.push(id)
    }

    // remove the last line break
    if(discipline_text.length > 0) {
        discipline_text = discipline_text.slice(0,-5);
    }

    // update the page
    if(discipline_text.length == 0) {
        $('discipline_to_list').innerHTML = '<span class="none_text">No disciplines</span>';
    }
    else {
        $('discipline_to_list').innerHTML = discipline_text;
    }

    clearList('person_discipline_ids');

    select=$('person_discipline_ids')
    for (i=0;i<discipline_ids.length;i++) {
        id=discipline_ids[i]
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

function addDiscipline(title,id) {    
    disciplines.push([title,id])
}

function addRole(group_membership_id,title,id) {
    roles.push([group_membership_id,title,id])
}

function removeRole(group_id,id) {

    for(var i = 0; i < roles.length; i++)
        if(roles[i][2] == id && roles[i][0]==group_id) {
            roles.splice(i, 1);
            break;
        }

    // update the page
    updateRoles(true,group_id);
}

function updateRoles(editable,group_id) {

    role_ids=new Array();
    role_text=""

    for (var i=0;i<roles.length;i++) {
        role=roles[i]
        if (role[0]==group_id) {
            title=role[1]
            id=role[2]

            role_text += title
            if (editable) {
                role_text += '&nbsp;&nbsp;<small style="vertical-align: middle;">[<a href="" onclick="javascript:removeRole('+group_id+','+id+'); return(false);">remove</a>]</small><br/>';
            }
            else {
                role_text += ", "
            }
            
            role_ids.push(id)
        }
    }

    // remove the last line break
    if(role_text.length > 0 && !editable) {
        role_text = role_text.slice(0,-2);
    }

    // update the page
    el='roles_'+group_id
    if(role_text.length == 0) {
        $(el).innerHTML = '<span class="none_text">No roles defined</span>';
    }
    else {
        $(el).innerHTML = role_text;
    }

    id_element="group_membership_role_ids_"+group_id;
    clearList(id_element);

    select=$(id_element)
    for (i=0;i<role_ids.length;i++) {
        id=role_ids[i]
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

function addSelectedRole(group_id) {
    
    el_possible="possible_roles_"+group_id;
    selected_option_index=$(el_possible).selectedIndex;    
    selected_option=$(el_possible).options[selected_option_index];
    title=selected_option.text;
    id=selected_option.value;    
    if(checkNotInRoleList(group_id,id)) {
        addRole(group_id,title,id);
        updateRoles(true,group_id);
    }
    else {
        alert('The following role had already been added:\n\n' +
            title);
    }
}

function checkNotInRoleList(group_id,id) {
    for (var i=0;i<roles.length;i++) {
        role=roles[i]
        if (role[0]==group_id && role[2]==id) return false;
    }
    return true;
}

function startRolesEdit(group_id) {
    edit_id="edit_roles_"+group_id;
    roles_list_id="roles_"+group_id;
    link_id='edit_link_'+group_id

    $(link_id).hide();
    
    Effect.toggle(edit_id,'blind',{
        duration:0.5
    });
    
    $(roles_list_id).className="box_editing_inner";
    $(roles_list_id).innerHTML="";
    new Effect.Highlight(roles_list_id,{});
    
    updateRoles(true,group_id);

}

function stopRolesEdit(group_id) {
    edit_id="edit_roles_"+group_id;
    roles_list_id="roles_"+group_id;
    link_id='edit_link_'+group_id

    $(link_id).show();
    
    
    Effect.toggle(edit_id,'blind',{
        duration:0.5
    });

    $(roles_list_id).className="box_editing_inner";
    new Effect.Highlight(roles_list_id,{});

    updateRoles(false,group_id);
}