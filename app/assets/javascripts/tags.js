var wrapTags =  function(list) {
    return $j.map(list, function(value) { return { name: value }; });
};

$j(document).ready(function () {
    $j('[data-role="seek-tagsinput"]').each(function () {
        var options = { tagClass: 'label label-default' };
        if($j(this).data('typeahead')) {
            var opts = {
                datumTokenizer: Bloodhound.tokenizers.obj.whitespace('name'),
                queryTokenizer: Bloodhound.tokenizers.whitespace
            };

            if(prefetchUrl = $j(this).data('typeahead-prefetch-url'))
                opts.prefetch = { url: prefetchUrl, filter: wrapTags };
            if(queryUrl = $j(this).data('typeahead-query-url'))
                opts.remote = { url: queryUrl, filter: wrapTags };
            if(localValues = $j(this).data('typeahead-local-values'))
                opts.local = wrapTags(localValues);

            var d = new Bloodhound(opts);
            d.initialize();

            options.typeaheadjs = {
                displayKey: 'name',
                valueKey: 'name',
                source: d.ttAdapter()
            };
        }

        $j(this).tagsinput(options);
    });
});
