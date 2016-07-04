$j(document).ready(function () {
    $j('[data-tooltip]').popover({
        html: false,
        animation: false,
        trigger: 'hover',
        placement: 'auto right',
        container: 'body',
        content: function () {
            return $j(this).data('tooltip');
        }
    });
});
