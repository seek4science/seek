$j(document).ready(function () {
    bindTooltips('body')
});

function bindTooltips(root_tag) {
    $j(root_tag + ' [data-tooltip]').popover({
        html: false,
        animation: false,
        trigger: 'hover',
        placement: 'auto right',
        container: 'body',
        delay: 500,
        content: function () {
            return $j(this).data('tooltip');
        }
    });
}