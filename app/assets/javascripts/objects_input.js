function loadObjectInputs(elem) {
    (elem?.item || $j('[data-role="seek-objectsinput"]')).each(function () {
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
            
            opts.limit=20;                

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

        if ($j(this).data("ontology")) {
            const tagsinput = $j(this).prev(".bootstrap-tagsinput").first();
            const input = $j(tagsinput).find("input.tt-input").first();
            $j(tagsinput).on("focusout", () => {
                if (input.val().length !== 0) $j(this).tagsinput("add", { id: input.val(), name: input.val() });
                // TODO: use the item event listener
                setTimeout(() => {
                    $j(input).val("");
                }, 1);
            });
        }
    });
}

$j(document).ready(loadObjectInputs);
