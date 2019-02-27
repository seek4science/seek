var disciplines=new Array();

function addSelectedDiscipline() {
    selected_option_index=$("possible_disciplines").selectedIndex;
    selected_option=$("possible_disciplines").options[selected_option_index];
    title=selected_option.text;
    id=selected_option.value;

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
    discipline_text='';
    type="Discipline";
    discipline_ids=new Array();

    for (var i=0;i<disciplines.length;i++) {
        discipline=disciplines[i];
        title=discipline[0];
        id=discipline[1];       
        discipline_text += '<b>' + type + '</b>: ' + title
        //+ "&nbsp;&nbsp;<span style='color: #5F5F5F;'>(" + contributor + ")</span>"
        + '&nbsp;&nbsp;<small style="vertical-align: middle;">'
        + '[<a href="" onclick="javascript:removeDiscipline('+id+'); return(false);">remove</a>]</small><br/>';
        discipline_ids.push(id);
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

    select=$('person_discipline_ids');
    for (i=0;i<discipline_ids.length;i++) {
        id=discipline_ids[i];
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

function addDiscipline(title,id) {    
    disciplines.push([title,id]);
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
