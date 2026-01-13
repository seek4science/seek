$j(document).ready(function () {
    let endChanged = false

    // set the end date 1 hour after the start date, unless the end date has been manually changed (can be reset by deleting).
    $j("#event_start_date").on('dp.change', function(e){
        if (endChanged) {
            return;
        }
        const startDate = e.date;
        const endDate = startDate.clone().add(1, 'hours');
        $j('#event_end_date').data('DateTimePicker').date(endDate);
        endChanged = false;
    });

    $j("#event_end_date").on('dp.change', function(e){
        endChanged = $j(this).val() !== '';
    });
});