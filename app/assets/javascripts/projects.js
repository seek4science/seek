// Namespacing...
var Projects = {
    memberships: [],
    membershipChanges: [],
    actions: {
        add: function () {
            var people = $j('select#people_ids').select2('data');
            var institution_tag = $j('select#institution_id').select2('data')[0];
            var institution_id = '';
            var institution_title = '';
            if (institution_tag) {
                institution_id = institution_tag.id;
                institution_title = institution_tag.text;
            }

            var errors = [];
            var peopleToRemove = [];

            if(institution_id == '') {
                errors.push(I18n.t('institution').toLowerCase() + ' is required!');
                $j("#institution_ids").parent('.form-group').addClass('has-error');
            } else {
                $j.each(people, function (index, value) {
                    if(Projects.getPersonIndex(Projects.memberships, value.id, institution_id) == -1) {
                        var change = {
                            person: { id: value.id, name: value.text },
                            institution: { id: institution_id, title: institution_title },
                            action: 'added',
                            membershipData: JSON.stringify({
                                person_id: value.id,
                                institution_id: institution_id,
                                institution_title: institution_title })
                        };
                        Projects.addChange(change);
                        peopleToRemove.push({ id: value.id });
                    } else {
                        errors.push(value.text + ' is already a member of the project through that institution.');
                    }
                });

               $j('select#institution_id').val([]).change();
               $j('select#people_ids').val([]).change();
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
