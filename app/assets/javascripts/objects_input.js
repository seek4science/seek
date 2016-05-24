function loadObjectInputs() {
    $j('[data-role="seek-objectsinput"]').each(function () {
        var options = { tagClass: 'label label-default',
            itemValue: 'id',
            itemText: 'name'
        };

        if($j(this).data('tagsLimit'))
            options.maxTags = $j(this).data('tagsLimit');

        if($j(this).data('typeahead')) {
            var opts = {
                datumTokenizer: Bloodhound.tokenizers.obj.whitespace('name'),
                queryTokenizer: Bloodhound.tokenizers.whitespace
            };

            if(prefetchUrl = $j(this).data('typeahead-prefetch-url'))
                opts.prefetch = { url: prefetchUrl };
            if(queryUrl = $j(this).data('typeahead-query-url'))
                opts.remote = { url: queryUrl };
            if(localValues = $j(this).data('typeahead-local-values'))
                opts.local = localValues;

            var d = new Bloodhound(opts);
            d.initialize();

            var template = $j(this).data('typeahead-template') || 'typeahead/hint';

            options.typeaheadjs = {
                displayKey: 'name',
                source: d.ttAdapter(),
                templates: {
                    suggestion: HandlebarsTemplates[template]
                }
            };
        }

        $j(this).tagsinput(options);

        var objects = $j(this).data('existingObjects');
        if(objects)
            for(var i = 0; i < objects.length; i++)
                $j(this).tagsinput('add', objects[i]);
    });
}

$j(document).ready(loadObjectInputs);
