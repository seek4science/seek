function nestedOptionsFromJSONArray(array,prompt_option_text) {
    var options = [];
    options.push($j('<option/>').val(0).text(prompt_option_text));

    //gather together by parent id
    var parents = {};
    for(var i = 0; i < array.length; i++) {
        var item = array[i];
        if (parents[item.parent_id]) {
            var parent = parents[item.parent_id];
            parent.children.push({id:item.id,title:item.title});
        }
        else {
            var parent = {title:item.parent_title,id:item.parent_id,children:[]};
            parent.children.push({id:item.id,title:item.title});
            parents[item['parent_id']]=parent;
        }
    }

    //build into optgroups, with options clustered according to parent
    for (parent_id in parents) {
        var parent=parents[parent_id];
        var group = $j('<optgroup/>').attr('label',parent.title);
        for(var i=0;i<parent.children.length;i++) {
            var child=parent.children[i];
            group.append($j('<option/>').val(child.id).text(child.title));
        }
        options.push(group);
    }

    return options;
}

var Associations = {};

// Object to control a list of existing associations
Associations.List = function (template, element, options) {
    this.template = template;
    this.element = element;
    this.element.data('associationList', this);
    this.listElement = $j('ul', this.element);
    this.items = [];
    options = options || {};
    this.onAdd = options.onAdd || function () {};
    this.onRemove = options.onRemove || function () {};
};

Associations.List.prototype.toggleEmptyListText = function () {
    var noText = $j('.no-item-text', this.element);

    if (this.items.length === 0)
        noText.show();
    else
        noText.hide();
};

Associations.List.prototype.add = function (association) {
    if (this.element.data('fieldName')) {
        association.fieldName = this.element.data('fieldName');
    }
    var newItem = new Associations.ListItem(this, association);

    this.items.push(newItem);
    this.toggleEmptyListText();
    this.onAdd(association);

};

Associations.List.prototype.remove = function (listItem) {
    var index = this.items.indexOf(listItem);
    if (index > -1) {
        var item = this.items[index];
        this.items.splice(index, 1);
        this.onRemove(item);
    }
    this.toggleEmptyListText();
};

Associations.List.prototype.exists = function (itemOrFunction) {
    if (typeof itemOrFunction === 'function') {
        return this.items.some(function (item) {
            return itemOrFunction(item.data);
        })
    } else {
        return this.items.includes(itemOrFunction);
    }
};

Associations.List.prototype.find = function (func) {
    return this.items.find(function (item) {
        return func(item.data);
    })
};

Associations.List.prototype.findDuplicate = function(association) {
    return this.items.find(function(item) {
        return item.id = association.id;
    });
}

Associations.List.prototype.removeAll = function () {
    this.items = [];
    this.listElement.html('');
    this.toggleEmptyListText();
};

// Object to control an element in the association list
Associations.ListItem = function (list, data) {
    this.list = list;
    this.data = data;

    // Create and append element to list
    this.element = $j(HandlebarsTemplates[this.list.template](data));
    this.list.listElement.append(this.element);

    // Bind remove event
    var listItem = this;
    this.element.on('click', '.remove-association', function () {
        listItem.remove();
    });
};

Associations.ListItem.prototype.remove = function () {
    this.element.remove();
    this.list.remove(this);
};

// A collection of lists, for example if you want to split associations into different lists depending on a certain
//  attribute.
Associations.MultiList = function (element, groupingAttribute) {
    this.element = element;
    this.element.data('associationList', this);
    this.groupingAttribute = groupingAttribute;
    this.lists = {};
};

Associations.MultiList.prototype.addList = function (attributeValue, list) {
    this.lists[attributeValue.toString()] = list;
};

Associations.MultiList.prototype.add = function (association) {
    var value = digValue(association, this.groupingAttribute);
    var list = this.lists[value.toString()];
    list.add(association);
};

Associations.MultiList.prototype.removeAll = function () {
    for(var key in this.lists) {
        if (this.lists.hasOwnProperty(key))
            this.lists[key].removeAll();
    }
};

Associations.MultiList.prototype.findDuplicate = function(association) {
    for(var key in this.lists) {
        var match = this.lists[key].findDuplicate(association);
        if (match) {
            return match;
        }
    }
}

// Object to control the association selection form.
Associations.Form = function (list, element) {
    this.list = list;
    this.element = element;
    this.element.data('associationForm', this);
    this.selectedItems = [];
    this.commonFieldElements = [];
};

Associations.Form.prototype.reset = function () {
    this.selectedItems = [];
};

Associations.Form.prototype.submit = function () {
    var commonFields = {};
    this.commonFieldElements.forEach(function (element) {
        var name = element.data('attributeName');
        if (element.is('select')) {     //  <select> tags store both the value and the selected option's text
            commonFields[name] = { value: element.val(),
                text: $j('option:selected', element).text() };
        } else {
            commonFields[name] = element.val();
        }
    });
    var list = this.list;
    this.selectedItems.forEach(function (selectedItem) {
        // Merge the common fields with the selected item's attributes
        var associationObject = $j.extend({}, commonFields, selectedItem);
        if (list.findDuplicate(associationObject)) {
            alert("The item '"+associationObject.title + "' has already been associated");
        }
        else {
            list.add(associationObject);
        }
    });

    if (this.afterSubmit)
        this.afterSubmit(this.selectedItems.length);

    this.reset();
};

// Object to represent a set of fields that the user can change to filter a candidate list of associations
Associations.FilterGroup = function (element, filterUrl) {
    this.element = element;
    this.filterUrl = filterUrl;
    this.list = $j('[data-role="seek-association-candidate-list"]', $j(element));
};

Associations.FilterGroup.prototype.filter = function () {
    var payload = {};

    $j('[data-role="seek-association-filter-field"]:not(:checkbox)', this.element).each(function () {
        var name = $j(this).data('attributeName');
        payload[name] = $j(this).val();
    });

    $j('[data-role="seek-association-filter-field"]:checkbox', this.element).each(function () {
        var name = $j(this).data('attributeName');
        payload[name] = $j(this).is(':checked');
    });

    var self = this;
    $j.ajax(self.filterUrl, {
            data: payload,
            success: function (data) {
                self.list.html(data);
            }
        }
    );
};

Associations.FilterGroup.prototype.reset = function () {
    $j(':input[data-role="seek-association-filter-field"]:not(:checkbox)', this.element).val('');
    $j(':input[data-role="seek-association-filter-field"]:checkbox', this.element).removeAttr('checked');
    this.filter();
};

$j(document).ready(function () {
    // Markup
    $j('[data-role="seek-associations-list"]').each(function () {
        var list = new Associations.List($j(this).data('templateName'), $j(this));
        var self = $j(this);

        var existingValues = $j('script[data-role="seek-existing-associations"]', self).html();
        if (existingValues) {
            JSON.parse(existingValues).forEach(function (value) {
                list.add(value);
            });
        }
    });

    $j('[data-role="seek-associations-list-group"]').each(function () {
        var multilist = new Associations.MultiList($j(this), $j(this).data('groupingAttribute'));
        var self = $j(this);
        $j('[data-role="seek-associations-list"]', self).each(function () {
            multilist.addList($j(this).data('multilistGroupValue'), $j(this).data('associationList'));
        });

        var existingValues = $j('script[data-role="seek-existing-associations"]', self).html();
        if (existingValues) {
            JSON.parse(existingValues).forEach(function (value) {
                multilist.add(value);
            });
        }
    });

    $j('[data-role="seek-association-form"]').each(function () {
        var element = this;
        var listId = $j(element).data('associationsListId');
        var list = $j('#' + listId).data('associationList'); // Get the List object from the DOM element
        var form = new Associations.Form(list, $j(this));

        // Strip the name of the element and store it as a data attribute, to stop it being submitted as a field in the
        //  main form
        $j(':input[data-role="seek-association-common-field"]', $j(element)).each(function () {
            $j(this).data('attributeName', this.name);
            this.name = '';
            form.commonFieldElements.push($j(this));
        });

        $j(element).on('click', '.selectable[data-role="seek-association-candidate"]', function () {
            $j(this).toggleClass('selected');
            if (!$j(this).parents('[data-role="seek-association-candidate-list"]').data('multiple')) {
                $j(this).siblings().removeClass('selected');
            }

            form.selectedItems = [];
            $j(this).parents('[data-role="seek-association-candidate-list"]').find('[data-role="seek-association-candidate"].selected').each(function () {
                // Merge common fields and association-specific fields into single object
                form.selectedItems.push({
                    id: $j(this).data('associationId'),
                    title: $j(this).data('associationTitle')
                });
            });

            return false;
        });

        $j('[data-role="seek-association-confirm-button"]', $j(element)).click(function (e) {
            e.preventDefault();
            $j('.selectable[data-role="seek-association-candidate"]', $j(element)).removeClass('selected');
            form.submit();
        });
    });

    $j('[data-role="seek-association-filter-group"]').each(function () {
        var filterGroup = new Associations.FilterGroup($j(this), $j(this).data('filterUrl'));
        var self = $j(this);

        // Strip the name of the element and store it as a data attribute, to stop it being submitted as a field in the
        //  main form
        $j('[data-role="seek-association-filter-field"]', self).each(function () {
            $j(this).data('attributeName', this.name);
            this.name = '';
        });

        $j('[data-role="seek-association-filter-field"]:text', self).keypress(function (e) {
            if (e.keyCode == 13) {
                e.preventDefault();
            }
        });

        $j('[data-role="seek-association-filter-field"]:text', self).keyup(function (e) {
            // If more than two characters were entered, or the input was cleared, or the ENTER key was pressed..
            if ($j(this).val().length == 0 || $j(this).val().length >= 2 || e.keyCode == 13) {
                filterGroup.filter();
            }
        });

        // If a non-text field was changed, trigger the filter
        $j('[data-role="seek-association-filter-field"]:not(:text)', self).change(function (e) {
            filterGroup.filter();
        });

        // If no initial association candidates provided, make a filter call to get some.
        if ($j.trim(filterGroup.list.html()) == '') {
            filterGroup.filter();
        }

        // Bind the FilterGroup object to the element so it can be accessed externally
        self.data('filterGroup', filterGroup);
    });
});
