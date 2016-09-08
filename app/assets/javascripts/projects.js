var organisms=new Array();
var roles = new Array();


function addSelectedOrganism() {
    selected_option_index=$("possible_organisms").selectedIndex;
    selected_option=$("possible_organisms").options[selected_option_index];
    title=selected_option.text;
    id=selected_option.value;

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
    organism_text='';
    type="Organism";
    organism_ids=new Array();

    for (var i=0;i<organisms.length;i++) {
        organism=organisms[i];
        title=organism[0];
        id=organism[1];
        organism_text += '<b>' + type + '</b>: ' + title
        //+ "&nbsp;&nbsp;<span style='color: #5F5F5F;'>(" + contributor + ")</span>"
        + '&nbsp;&nbsp;<small style="vertical-align: middle;">'
        + '[<a href="" onclick="javascript:removeOrganism('+id+'); return(false);">remove</a>]</small><br/>';
        organism_ids.push(id);
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

    select=$('project_organism_ids');
    for (i=0;i<organism_ids.length;i++) {
        id=organism_ids[i];
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

function addOrganism(title,id) {
    organisms.push([title,id]);
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
var Projects = {
    memberships: [],
    membershipChanges: [],
    actions: {
        add: function () {
            var people = $j('#people_ids').tagsinput('items');
            var institution_id = $j("#institution_ids").val();
            var institution_title = $j("#institution_ids option:selected").text();
            var errors = [];
            var toRemove = [];

            if(institution_id == '') {
                errors.push('Please select an institution!');
                $j("#institution_ids").parent('.form-group').addClass('has-error');
            } else {
                $j.each(people, function (index, value) {
                    if(Projects.getPersonIndex(Projects.memberships, value.id, institution_id) == -1) {
                        var change = {
                            person: { id: value.id, name: value.name },
                            institution: { id: institution_id, title: institution_title },
                            action: 'added',
                            membershipData: JSON.stringify({
                                person_id: value.id,
                                institution_id: institution_id,
                                institution_title: institution_title })
                        };
                        Projects.addChange(change);
                        toRemove.push({ id: value.id });
                    } else {
                        errors.push(value.name + ' is already a member of the project through that institution.');
                    }
                });

                for(var i = 0; i < toRemove.length; i++)
                    $j('#people_ids').tagsinput('remove', toRemove[i]);
            }

            if(errors.length > 0)
                alert(errors.join("\n"));
        },
        undo: function () {
            var item = $j(this).parent('.institution_member');
            var personId = item.data('personId');
            var institutionId = item.data('institutionId');
            Projects.removeChange(personId, institutionId);
        },
        remove: function () {
            var item = $j(this).parent('.institution_member');
            var change = {
                id: item.data('membershipId'),
                person: { id: item.data('personId'), name: item.data('personName') },
                institution: { id: item.data('institutionId'), title: item.data('institutionTitle') },
                action: 'removed'
            };
            Projects.addChange(change);
        },
        flag: function () {
            var item = $j(this).parent('.institution_member');
            $j('#leaving-person-id').val(item.data('personId'));
            $j('#leaving-person-name').val(item.data('personName'));
            $j('#leaving-person-institution-id').val(item.data('institutionId'));
            $j('#leaving-person-institution-title').val(item.data('institutionTitle'));
            $j('#leaving-membership-id').val(item.data('membershipId'));
            $j('#leaving-date-form').modal('show');
        },
        confirmFlag: function () {
            var change = {
                id: $j('#leaving-membership-id').val(),
                person: { id: $j('#leaving-person-id').val(), name: $j('#leaving-person-name').val() },
                institution: { id: $j('#leaving-person-institution-id').val(), title: $j('#leaving-person-institution-title').val() },
                date: $j('#leaving_date').val(),
                action: 'flagged'
            };
            $j('#leaving-date-form').modal('hide');
            Projects.addChange(change);
        },
        unflag: function () {
            var item = $j(this).parent('.institution_member');
            var change = {
                id: item.data('membershipId'),
                person: { id: item.data('personId'), name: item.data('personName') },
                institution: { id: item.data('institutionId'), title: item.data('institutionTitle') },
                action: 'unflagged'
            };
            Projects.addChange(change);
        }
    }
};

Projects.getPersonIndex = function (set, personId, institutionId) {
    for(var i = 0; i < set.length; i++) {
        if(set[i].person.id == personId)
            if(set[i].institution.id == institutionId)
                return i;
    }

    return -1;
};

Projects.removeChange = function (personId, institutionId) {
    var index = Projects.getPersonIndex(Projects.membershipChanges, personId, institutionId);
    if(index > -1)
        Projects.membershipChanges.splice(index, 1);

    Projects.renderMemberships();
};

Projects.addChange = function (change) {
    var index = Projects.getPersonIndex(Projects.membershipChanges, change.person.id, change.institution.id);
    if(index > -1)
        Projects.membershipChanges[index] = change;
    else {
        Projects.membershipChanges.push(change);
    }
    Projects.renderMemberships();
};

Projects.renderMemberships = function () {
    var membershipListElement = $j('#project_institutions');
    var changeListElement = $j('#change-list');

    var addToList = function (membership) {
        var selector = '.institution_members[data-institution-id="' + membership.institution.id + '"]';
        var institutionElement = membershipListElement.find(selector);
        if(institutionElement.length === 0) {
            // Create institution if not already there
            membershipListElement.append(HandlebarsTemplates['projects/institution'](membership.institution));
            institutionElement = membershipListElement.find(selector);
        }
        var templateName = membership.action === 'added' ? 'projects/new_member' : 'projects/member';
        institutionElement.append(HandlebarsTemplates[templateName](membership));
    };

    // Render the existing members
    membershipListElement.html('');
    for(var i = 0; i < Projects.memberships.length; i++) {
        var membership = Projects.memberships[i];
        addToList(membership);
    }

    // Render the list of changes made
    var hasChanges = Projects.membershipChanges.length !== 0;
    changeListElement.html('').toggle(hasChanges);
    $j('#empty-change-list').toggle(!hasChanges);
    $j('#undo-all').toggle(hasChanges);
    for(i = 0; i < Projects.membershipChanges.length; i++) {
        var change = Projects.membershipChanges[i];
        var element = membershipListElement.find('[data-membership-id="' + change.id + '"]')[0];
        if(element)
            $j(element).addClass('mutated-membership ' + change.action + '-membership');
        changeListElement.append(HandlebarsTemplates['projects/changes/' + change.action + '_member'](change));
        // In the case that someone was added, also add them to the membership list
        if(change.action === 'added')
            addToList(change);
    }
};

$j(document).ready(function () {
    $j('#project-admin-page').on('click', '.undo-action', Projects.actions.undo);
    $j('#project-admin-page').on('click', '.remove-action', Projects.actions.remove);
    $j('#project-admin-page').on('click', '.flag-action', Projects.actions.flag);
    $j('#project-admin-page').on('click', '.unflag-action', Projects.actions.unflag);
    $j('#project-admin-page').on('click', '#confirm-leaving', Projects.actions.confirmFlag);

    $j('#undo-all').click(function () {
        Projects.membershipChanges = [];
        Projects.renderMemberships();
        return false;
    });

    $j("#institution_ids").change(function () { $j(this).parent('.form-group').removeClass('has-error'); });
});
