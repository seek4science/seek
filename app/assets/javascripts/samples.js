var Samples = {};

Samples.initTable = function (selector, enableRowSelection, opts) {
    var table;
    enableRowSelection = enableRowSelection || false;
    opts = opts || {};

    $j('table tfoot th', selector).each( function () {
        var title = $j(this).text();
        $j(this).html('<input type="text" class="form-control" placeholder="Search '+title+'" />');
    });

    var options = $j.extend({}, opts, {
        "lengthMenu": [ 5, 10, 25, 50, 75, 100 ],
        "pageLength": 10,
        dom: 'lr<"samples-table-container"t>ip', // Needed to place the buttons
        "columnDefs": [{
            "targets": [ 0, 1 ],
            "visible": false,
            "searchable": false
        }]
        //"initComplete": function () {  // THIS IS TOO SLOW - CRASHES BROWSER
        //    console.log("Hiding empty columns");
        //    table.columns().flatten().each(function (columnIndex) {
        //        console.log("Col " + columnIndex);
        //        if(table.columns(columnIndex).data()[0].every(function(v) { return v === null; }))
        //            table.column(columnIndex).visible(false);
        //    });
        //}
    });

    if($j('table', selector).data('sourceUrl'))
        options.ajax = $j('table', selector).data('sourceUrl');

    if(options.ajax) {
        options.columns = [{ data: 'id'},{ data: 'title'}];
        $j('table thead th', selector).each(function (index, column) {
            if($j(column).data('accessorName'))
                options.columns.push({ data: 'data.' + $j(column).data('accessorName') });
        });
    }

    // Date Columns
    var dateColumns = [];
    $j('table thead th', selector).each(function (index, column) {
        if($j(column).data('columnType') == 'Date' ||
           $j(column).data('columnType') == 'DateTime') {
            dateColumns.push(index);
        }
    });
    if(dateColumns.length > 0) {
        options["columnDefs"].push({
            "targets": dateColumns,
            "type": "date"
        });
    }
    // The following only needed if we're loading the data from ajax

    if($j('table', selector).data('sourceUrl')) {
        // Strain columns
        var strainColumns = [];
        $j('table thead th', selector).each(function (index, column) {
            if($j(column).data('columnType') == 'SeekStrain') {
                strainColumns.push(index);
            }
        });
        if(strainColumns.length > 0) {
            options["columnDefs"].push({
                "targets": strainColumns,
                "render": function (data, type, row) {
                    if(data && data.id) {
                        if (data.title)
                            return '<a href="/strains/' + data.id + '">' + data.title + '</a>';
                        else
                            return '<span class="none_text">' + data.id + '</span>';
                    } else {
                        return '<span class="none_text">Not specified</span>';
                    }
                }
            });
        }
        // SEEK sample columns
        var seekSampleColumns = [];
        $j('table thead th', selector).each(function (index, column) {
            if(['SeekSample','SeekSampleMulti'].includes($j(column).data('columnType'))) {
                seekSampleColumns.push(index);
            }
        });
        if(seekSampleColumns.length > 0) {
            options["columnDefs"].push({
                "targets": seekSampleColumns,
                "render": function (data, type, row) {
                    var values = Array.isArray(data) ? data : [data];
                    var result = $j.map(values, function(value, i) {
                        if(value && value.id) {
                            if (value.title)
                                return '<a href="/samples/' + value.id + '">' + value.title + '</a>';
                            else
                                return '<span class="none_text">' + (value.id || value.title) + '</span>';
                        } else {
                            return '<span class="none_text">Not specified</span>';
                        }
                    })
                    return result.join(", ")
                }
            });
        }

        // Title column
        $j('table thead th', selector).each(function (index, column) {
            if($j(column).data('titleColumn')) {
                options["columnDefs"].push({
                    "targets": [index],
                    "render": function (data, type, row) {
                        return '<a href="/samples/' + row.id + '">' + row.title + '</a>';
                    }
                });
            }
        });
    }

    if(enableRowSelection) {
        $j.extend(options, options, {
            dom: '<"row"<"col-sm-6"l><"col-sm-6 text-right"B>>r<"samples-table-container"t>ip', // Needed to place the buttons
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

    $j('table tbody td.sample-field-error div', selector).popover({
        html: true,
        placement: 'top',
        trigger: 'hover'
    });
    return table;
};
