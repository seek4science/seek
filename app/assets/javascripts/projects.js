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

// Namespacing...
var projectActions = {
    add: function () {
        var people = $j('#people_ids').tagsinput('items');

        $j.each(people, function (index, value) {
            var institution_id = $j("#institution_ids").val();
            var institution_title = $j("#institution_ids option:selected").text();
            var change = {
                person: { id: value.id, name: value.name },
                institution: { id: institution_id, title: institution_title},
                action: 'added',
                membershipData: JSON.stringify({person_id: value.id, institution_id: institution_id, institution_title: institution_title})
            };
            membershipChanges.push(change);
            renderMemberships();
        });

        $j('#people_ids').tagsinput('removeAll');
    },
    undo: function () {
        var item = $j(this).parent('.institution_member');
        var id = parseInt(item.data('personId'));
        console.log(id);
        for(var i = 0; i < membershipChanges.length; i++) {
            if(membershipChanges[i].person.id === id) {
                membershipChanges.splice(i, 1);
                break;
            }
        }
        renderMemberships();
    },
    remove: function () {
        var item = $j(this).parent('.institution_member');
        var change = {
            id: parseInt(item.data('membershipId')),
            person: { id: item.data('personId'), name: item.data('personName') },
            action: 'removed'
        };
        membershipChanges.push(change);
        renderMemberships();
    }
};

$j(document).ready(function () {
    $j('#project-admin-page').on('click', '.undo-action', projectActions.undo);
    $j('#project-admin-page').on('click', '.remove-action', projectActions.remove);
    //$j('#project-admin-page').on('click', '.flag-action', projectActions.flag);
});

var memberships = []; // Array to hold all the current project memberships. Should not be modified!
var membershipChanges = []; // to hold all the unsaved changes made on the current page

function renderMemberships() {
    var membershipListElement = $j('#project_institutions');
    var changeListElement = $j('#change-list');

    var addToList = function (membership) {
        var institutionElement = membershipListElement.find('[data-institution-id="' + membership.institution.id + '"]');
        if(institutionElement.length === 0) {
            // Create institution if not already there
            membershipListElement.append(HandlebarsTemplates['projects/institution'](membership.institution));
            institutionElement = membershipListElement.find('[data-institution-id="' + membership.institution.id + '"]');
        }
        var templateName = membership.action === 'added' ? 'projects/new_member' : 'projects/member';
        institutionElement.append(HandlebarsTemplates[templateName](membership));
    };

    // Render the existing members
    membershipListElement.html('');
    for(var i = 0; i < memberships.length; i++) {
        var membership = memberships[i];
        addToList(membership);
    }

    // Render the list of changes made
    changeListElement.html('').toggle(membershipChanges.length !== 0);
    $j('#empty-change-list').toggle(membershipChanges.length === 0);
    for(i = 0; i < membershipChanges.length; i++) {
        var change = membershipChanges[i];
        var element = membershipListElement.find('[data-membership-id="' + change.id + '"]')[0];
        if(element) {
            $j(element).addClass(change.action + '-membership');
        }
        changeListElement.append(HandlebarsTemplates['projects/changes/' + change.action + '_member'](change));
        // In the case that someone was added, also add them to the membership list
        if(change.action === 'added')
            addToList(change);
    }
}
