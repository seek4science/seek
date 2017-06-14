//= require moment
//= require eonasdan-bootstrap-datetimepicker

$j(document).ready(function () {
    $j('[data-calendar]').each(function () {
        var showTime = $j(this).data('calendar') === 'mixed';
        $j(this).datetimepicker({
            format: showTime ? 'YYYY-MM-DD HH:mm' : 'YYYY-MM-DD',
            sideBySide: showTime
        });
    });
});
