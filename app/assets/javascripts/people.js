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
