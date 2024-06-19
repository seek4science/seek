var Datafiles = {};

Datafiles.initTable = function (selector, opts) {
    var table;
    opts = opts || {};

    $j('table tfoot th', selector).each( function () {
        var title = $j(this).data().searchTitle;
        $j(this).html('<input type="text" class="form-control" placeholder="Search '+title+'" />');
    });

    var options = $j.extend({}, opts, {
        "lengthMenu": [ 5, 10, 25, 50, 75, 100 ],
        "pageLength": 10,
        dom: '<"row"<"col-sm-10"lr>><"datafiles-table-container"t>ip' // Needed to place the buttons
    });

    table = $j('table', selector).DataTable(options);

    // DataTable
    table.columns().every(function () {
        var column = this;

        $j('input', this.footer()).on('keyup change', function () {
            if (column.search() !== this.value)
                column.search(this.value).draw();
        }).on('keydown', function (event) { // Stop enter key submitting form
            if(event.keyCode == 13) {
                event.preventDefault();
                return false;
            }
        });
    });

    $j('table tbody td.datafile-field-error div', selector).popover({
        html: true,
        placement: 'top',
        trigger: 'hover'
    });
    return table;
};