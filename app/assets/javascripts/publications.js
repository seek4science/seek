function transferProjectIds() {
    // need to transfer project ids from the project selector to the hidden element in the 'register' form
    var selectedProjects = Sharing.projectsSelector.selected.map(function (n) {
        return n.id
    });

    var registerForm = $j('form#new_publication');

    for (var i = 0; i < selectedProjects.length; i++) {
        var element = "<input multiple='multiple' value='" + selectedProjects[i] + "' type='hidden' name='publication[project_ids][]' id='publication_project_ids'>";
        registerForm.append(element);
    }
}

/**
 * Populate a Select2 element with authors.
 * Supports PubMed XML format or {given, family} arrays.
 * @param {jQuery} select - The Select2 element
 * @param {Array|Object} authors - Either XML AuthorList or array of {given, family}
 */
function populateAuthors(select, authors) {
    let authorArray = [];

    // Check if authors come from PubMed XML
    if (authors.AuthorList) {
        const list = Array.isArray(authors.AuthorList.Author)
            ? authors.AuthorList.Author
            : [authors.AuthorList.Author];

        authorArray = list.map(a => ({ given: a.ForeName, family: a.LastName }));
    } else if (Array.isArray(authors)) {
        // Already in {given, family} format
        authorArray = authors;
    } else {
        console.warn("Unsupported author format:", authors);
        return;
    }

    // Populate Select2
    authorArray.forEach(author => {
        const fullName = `${author.given} ${author.family}`;
        let option = select.find(`option[value="${fullName}"]`);
        if (!option.length) {
            const newOption = new Option(fullName, fullName, true, true);
            select.append(newOption);
        } else {
            option.prop('selected', true);
        }
    });

    // Remove empty option and trigger update
    select.find('option[value=""]').remove();
    select.trigger('change');
}
