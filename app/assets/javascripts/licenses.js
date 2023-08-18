var Licenses = {
    init: function () {
        $j('[data-seek-license-select="true"]').on('select2:select', Licenses.displayUrl);
        $j('[data-seek-license-select="true"]').trigger('select2:select');
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
