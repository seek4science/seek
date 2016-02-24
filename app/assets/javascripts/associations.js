function optionsFromArray(array) {
    var options = [];

    for(var i = 0; i < array.length; i++)
        options.push($j('<option/>').val(array[i][1]).text(array[i][0])[0]);

    return options;
}

var associations = {
    toggleEmptyListText: function (list) {
        var noText = $j('.no-item-text', list);

        if($j('.association-list-item', list).length == 0)
            noText.show();
        else
            noText.hide();
    }
};

$j(document).ready(function () {
    $j('[data-role="seek-associations-list"]').each(function () {
        var self = $j(this);
        var existingValues = JSON.parse($j('script[data-role="seek-existing-associations"]', self).html());

        var template = HandlebarsTemplates[self.data('templateName')];
        var ulElement = $j('ul', self);

        existingValues.each(function (value) {
            ulElement.append(template(value));
        });
        associations.toggleEmptyListText(self);

        $j(this).on('click', '.remove-association', function () {
            $j(this).parent().remove();
            associations.toggleEmptyListText(self);
        });

    });

    $j('[data-role="seek-confirm-association-button"]').click(function (e) {
        e.preventDefault();
        var modal = $j(this).parents('.new-association-modal');
        var associationObject = {};

        // Build a JSON object from the inputs in the modal
        $j(':input', modal).each(function (_, input) {
            if($j(input).attr('name')) {
                var name = $j(input).attr('name').replace('_association_','');
                associationObject[name] = $j(this).val();
            }
        });

        var list = $j('#'+$j(this).data('associationsListId'));
        var template = HandlebarsTemplates[list.data('templateName')];
        list.find('ul').append(template(associationObject));
        associations.toggleEmptyListText(list);

        modal.modal('hide');
        return false;
    });
});
