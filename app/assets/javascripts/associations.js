function optionsFromArray(array) {
    var options = [];

    for(var i = 0; i < array.length; i++)
        options.push($j('<option/>').val(array[i][1]).text(array[i][0])[0]);

    return options;
}

var Associations = {};

// Object to control a list of existing associations
Associations.List = function (template, element) {
    this.template = template;
    this.element = element;
    this.element.data('associationList', this);
    this.listElement = $j('ul', this.element);
    this.items = [];
};

Associations.List.prototype.toggleEmptyListText = function () {
    var noText = $j('.no-item-text', $j(this.element));

    if(noText.length == 0)
        noText.show();
    else
        noText.hide();
};

Associations.List.prototype.add = function (association) {
    this.items.push(new Associations.ListItem(this, association));
    this.toggleEmptyListText();
};

Associations.List.prototype.remove = function (listItem) {
    var index = this.items.indexOf(listItem);
    if (index > -1)
        array.splice(index, 1);
    this.toggleEmptyListText();
};

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
    this.element.on('click', 'remove-association', function () {
        listItem.remove();
    });
};

Associations.ListItem.prototype.remove = function () {
    this.list.remove(this);
};


// Object to control the association selection form.
Associations.Form = function (list) {
    this.list = list;
    this.selectedItems = [];
    this.commonFieldElements = [];
};

Associations.Form.prototype.reset = function () {
    this.selectedItems = [];
};

Associations.Form.prototype.submit = function () {
    var commonFields = {};
    this.commonFieldElements.each(function () {
        var name = this.data('attributeName');
        if(this.is('select')) {     //  <select> tags store both the value and the selected option's text
            commonFields[name] = { value: this.val(),
                text: $j('option:selected', this).text() };
        } else {
            commonFields[name] = this.val();
        }
    });

    var list = this.list;
    this.selectedItems.each(function () {
        // Merge the common fields with the selected item's attributes
        var associationObject = $j.extend({}, commonFields, this);
        list.add(associationObject);
    });

    if(this.afterSubmit)
        this.afterSubmit(this.selectedItems.length);

    this.reset();
};


$j(document).ready(function () {
    $j('[data-role="seek-associations-list"]').each(function () {
        var list = new Associations.List($j(this).data('templateName'), $j(this));
        var self = $j(this);
        var existingValues = JSON.parse($j('script[data-role="seek-existing-associations"]', self).html());

        existingValues.each(function () {
            list.add(this)
        });
    });

    $j('[data-role="seek-association-filter"]').keypress(function (e) {
        // If more than two characters were entered, or the input was cleared, or the ENTER key was pressed..
        var filter = this;
        if($j(this).val().length == 0 || $j(this).val().length >= 2 || e.keyCode == 13) {
            $j.ajax($j(this).data('filterUrl'), {
                    data: { filter: $j(this).val() },
                    success: function (data) { $j(filter).siblings('[data-role="seek-association-candidate-list"]').html(data); }
                }
            );
            if(e.keyCode == 13)
                e.preventDefault();
        }
    });
});
