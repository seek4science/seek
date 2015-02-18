var wrapTags =  function(list) {
    return $j.map(list, function(value) { return { name: value }; });
};

$j(document).ready(function () {
    $j('[data-role="seek-tagsinput"]').each(function () {
        var options = { tagClass: 'label label-default' };
        if($j(this).data('typeahead')) {
            var d = new Bloodhound({
                datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
                queryTokenizer: Bloodhound.tokenizers.whitespace,
                prefetch: { url: $j(this).data('typeahead-prefetch-url'), filter: wrapTags },
                remote: { url: $j(this).data('typeahead-query-url'), filter: wrapTags }
            });

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
