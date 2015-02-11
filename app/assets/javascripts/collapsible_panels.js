// Similar to bootstrap's 'collapse' but doesn't require IDs, will collapse the sibling div.panel-collapse.
$j(document).ready(function (){
    $j('body').on('click.collapse-next.data-api', '[data-toggle=collapse-next]', function (e) {
        $j(this).siblings('.panel-collapse').collapse('toggle');
    });
});
