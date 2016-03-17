var Samples = {};

Samples.initTable = function (selector, enableRowSelection) {
    var table;
    enableRowSelection = enableRowSelection || false;

    $j('table tfoot th', selector).each( function () {
        var title = $j(this).text();
        $j(this).html('<input type="text" class="form-control" placeholder="Search '+title+'" />');
    });

    var options = {
        "lengthMenu": [ 5, 10, 25, 50, 75, 100 ],
        dom: 'lrtip', // Needed to place the buttons
        "columnDefs": [{
            "targets": [ 0, 1 ],
            "visible": false,
            "searchable": false
        }]
    };

    if(enableRowSelection) {
        $j.extend(options, options, {
            dom: '<"row"<"col-sm-6"l><"col-sm-6 text-right"B>>rtip', // Needed to place the buttons
            buttons: [
            {
                text: 'Select All',
                action: function () {
                    table.rows().deselect();
                    table.rows( {search:'applied'} ).select();
                }
            },
            'selectNone'
        ],
            language: {
            buttons: {
                selectNone: "Clear Selection"
            }
        },
            "select": {
            style: 'multi'
        }});

        $j('table tbody tr', selector).addClass('clickable');
    }

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

    return table;
};