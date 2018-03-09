var wrapTags =  function(list) {
    return $j.map(list, function(value) { return { name: value }; });
};

var detectDuplicates = function (d1, d2) {
    return d1.name == d2.name;
};

$j(document).ready(function () {
    $j('[data-role="seek-tagsinput"]').each(function () {
        var options = { tagClass: 'label label-default' };
        if($j(this).data('tagsLimit'))
            options.maxTags = $j(this).data('tagsLimit');
        if($j(this).data('typeahead')) {
            var opts = {
                datumTokenizer: Bloodhound.tokenizers.obj.whitespace('name'),
                queryTokenizer: Bloodhound.tokenizers.whitespace,
                dupDetector: detectDuplicates
            };

            if(prefetchUrl = $j(this).data('typeahead-prefetch-url'))
                opts.prefetch = { url: prefetchUrl, filter: wrapTags, cache: false };
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
