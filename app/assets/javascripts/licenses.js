var Licenses = {
    init: function () {
        $j('[data-role="seek-license-select"]').change(Licenses.displayUrl);
        $j('[data-role="seek-license-select"]').change();
        $j('[data-role="seek-license-select"]').select2({ theme: 'bootstrap' });
    },

    displayUrl: function () {
        var element = $j('option:selected', $j(this));
        var link = $j('#license-url');
        if (link.length) {
            var block = link.parents('.license-url-block');

            if (element.data('url')) {
                block.show();
            } else {
                block.hide();
            }

            link.attr('href', element.data('url'));
            link.html(element.data('url'));
        }
    }
}
