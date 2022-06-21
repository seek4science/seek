var AuthorForm = {
    recalculatePositions: function () {
        $j('#author-form .author').each(function (index, item) {
            $j('.author-position-label', $j(item)).html(index + 1);
            $j('.author-handle input', $j(item)).val(index + 1);
        });
    },

    bindSortable: function () {
        $j('#author-list').sortable({
            items: '.author',
            handle: '.author-handle'
        }).on('sortupdate', function () {
            AuthorForm.recalculatePositions();
        });
    },

    add: function(creator) {
        var list = $j('#author-list');
        var index = 0;
        $j('.author', list).each(function () {
            var newIndex = parseInt($j(this).data('index'));
            if (newIndex > index) {
                index = newIndex;
            }
        });
        index++;
        creator.field = list.data('fieldName');
        creator.index = index;
        creator.identifier = AuthorForm.getCreatorIdentifier(creator);
        if (creator.identifier) {
            var duplicate = AuthorForm.checkDuplicate(creator);
            if (duplicate) {
                duplicate.highlight('red');
            } else {
                list.append(HandlebarsTemplates['associations/assets_creator'](creator));
            }
        }

        AuthorForm.recalculatePositions();
        AuthorForm.toggleEmptyListText();
    },

    remove: function () {
        var author = $j(this).parents('.author');
        var destroyToggle = $j('input[data-role="destroy"]', author);
        if (destroyToggle.length) {
            destroyToggle.val('1');
            author.hide();
        } else {
            author.remove();
        }

        author.toggleClass('author'); // Needed or it will still affect the positions of remaining authors.

        AuthorForm.recalculatePositions();
        AuthorForm.toggleEmptyListText();
    },

    checkDuplicate: function (creator) {
        var existing = $j('#author-list .author[data-identifier="' + creator.identifier.toString() + '"]');

        return existing.length ? existing : false;
    },

    toggleEmptyListText: function () {
        if ($j('#author-list .author').length) {
            $j('#empty-change-list').hide();
        } else {
            $j('#empty-change-list').show();
        }
    },

    openModal: function () {
        $j('#new-author-modal').modal('show');
        $j('#author-given-name').focus();
    },

    submitModal: function () {
        var inputs = $j('#new-author-modal :input[type=text]');
        var obj = {};
        inputs.each(function (index, input) {
            var i = $j(input);
            obj[i.data('field')] = i.val();
            i.val('');
        });

        AuthorForm.add(obj);
        $j('#new-author-modal').modal('hide');
    },

    getCreatorIdentifier: function (creator) {
        if (creator.creator_id) {
            return creator.creator_id;
        } else if (creator.orcid) {
            return creator.orcid;
        } else if (creator.given_name && creator.family_name) {
            return creator.given_name + ' ' + creator.family_name;
        } else {
            return null;
        }
    }
}
