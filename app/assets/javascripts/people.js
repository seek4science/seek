var disciplines=new Array();

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

function updateWorkGroupIds(){
    var wg_ids_element = $('person_work_group_ids');
    var wg_ids = [];
    var checkbox_elements = document.getElementsByClassName('work_group_checkbox');
    for(var i = 0; i < checkbox_elements.length ; i++){
        var checkbox = checkbox_elements[i];
        if (checkbox.checked){
            wg_ids.push(checkbox.value);
        }
    }

    wg_ids_element.setValue(wg_ids);
}

function removePersonFromAdminDefinedRole(role,project_id) {
    var display_id = role+"_project_"+project_id;
    $(display_id).remove();
    var select = $('_roles_'+role);
    var options = select.childElements().select(function(c){return c.selected && c.value==project_id})
    if (options.length>0) {
        options[0].selected=false;
    }
    if (select.childElements().select(function(c){return c.selected}).length==0) {
        addNoProjectAssignedForAdminDefinedRole(role);
    }
}

function addPersonToAdminDefinedRole(role) {
    var selection = $('possible_project_for_'+role);
    var selected_option = selection.options[selection.selectedIndex];
    var project_id = selected_option.value;
    var project_name = selected_option.text;

    removeNoProjectAssignedForAdminDefinedRole(role);

    if (!isAdminDefinedRoleAlreadySelected(role,project_id)) {
        var select = $('_roles_'+role);
        var options = select.childElements().select(function(c){return !c.selected && c.value==project_id})
        if (options.length>0) {
            options[0].selected=true;
        }

        var list_block = $('project_list_for_'+role);
        var list_item = "<li id='"+role+"_project_"+project_id+"'>"+project_name+"&nbsp;";
        var remove_link = "<a href=\"javascript:removePersonFromAdminDefinedRole('"+role+"',"+project_id+");\">[remove]</a>";
        list_item = list_item + remove_link;
        list_item = list_item +"</li>";
        list_block.insert(list_item);
    }
    else {
        alert("The role is already selected for that project");
    }
}
//remove the list item that says no projects defined (with the id no_projects_for_$role
function removeNoProjectAssignedForAdminDefinedRole(role) {
    var id = "no_projects_for_"+role;
    if ($(id)) {
        $(id).remove();
    }
}

//adds a list item to indicate there are no projects for this role, with the id no_projects_for_$role
function addNoProjectAssignedForAdminDefinedRole(role) {
    var list_block = $('project_list_for_'+role);
    var list_item = "<li id='no_projects_for_"+role+"' class='none_text'>No projects assigned</li>";
    list_block.insert(list_item);
}

function isAdminDefinedRoleAlreadySelected(role,project_id) {
    var select = $('_roles_'+role);
    var options = select.childElements().select(function(c){return c.selected && c.value==project_id});
    return options.length>0;
}

var positions = {
    remove: function () {
        $j(this).parent('li').remove();
    },
    add: function () {
        var addition = { position: { id: $j(this).val(), name: $j(this).find("option:selected").text() },
            group: { id: $j(this).data('groupId') },
            editable: true };
        var element = $j('div.project-positions-group[data-group-id='+addition.group.id+'] .roles');
        var existing = element.find('li[data-position-id='+addition.position.id+']');
        if(element.find('li[data-position-id='+addition.position.id+']').length == 0)
            element.append(HandlebarsTemplates['positions/position'](addition));

        $j(this).val('');
    },
    render: function (positionData) {
        for(var i = 0; i < positionData.length; i++) {
            var group = positionData[i];
            var groupElement = $j('div.project-positions-group[data-group-id='+group.id+'] .roles');
            groupElement.html('');
            for(var j = 0; j < group.positions.length; j++) {
                var position = group.positions[j];
                position.group = { id: group.id };
                groupElement.append(HandlebarsTemplates['positions/position'](position));
            }
        }
    }
};
