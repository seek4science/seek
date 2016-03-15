$j(document).ready(function () {
    var samplesList = $j('#sample_to_list').data('associationList');
    var batchSamplesForm = new Associations.Form(samplesList, $j('#AddSamplesFromDataFileModal'));
    $j('#AddSamplesFromDataFileModal :input[data-role="seek-association-common-field"]').each(function () {
        $j(this).data('attributeName', this.name);
        this.name = '';
        batchSamplesForm.commonFieldElements.push($j(this));
    });

    var samplesTable;

    function initSamplesTable() {
        samplesTable = $j('#data-file-samples-table table').DataTable({
            "lengthMenu": [ 5, 10, 25, 50, 75, 100 ],
            "select": {
                style: 'multi'
            },
            "columnDefs": [{
                "targets": [ 0, 1 ],
                "visible": false,
                "searchable": false
            }]
        });
        // When at least one sample is selected, unlock step 3
        var handleRowSelect = function ( e, dt, type, indexes ) {
            var selectedRows = samplesTable.rows({ selected: true });

            batchSamplesForm.selectedItems = [];
            selectedRows.every(function () {
                batchSamplesForm.selectedItems.push({
                    id: this.data()[0],
                    title: this.data()[1]
                });
            });

            if(selectedRows.count() > 0) {
                wizard.step(3).unlock();
            } else {
                wizard.step(3).lock();
            }
        };
        samplesTable.on('select', handleRowSelect);
        samplesTable.on('deselect', handleRowSelect);
    }
    initSamplesTable();

    $j('#add-batch-sample-btn').click(function () {
        batchSamplesForm.submit();
    });

    $j('#data-file-samples-select-all').click(function () {
        samplesTable.rows().select();
        return false;
    });
    $j('#data-file-samples-select-none').click(function () {
        samplesTable.rows().deselect();
        return false;
    });
    $j('#clear-all-samples-btn').click(function () {
        if(confirm("Are you sure you wish to remove all samples from this assay?")) {
            samplesList.removeAll();
        }
        return false;
    });

    // Wizard steps
    var wizard = new Wizards.Wizard($j('#AddSamplesFromDataFileModal'));

    // On final step, show the confirm button
    wizard.step(3).onShow = function () {
        $j('#add-batch-sample-btn').show();
    };
    wizard.step(3).onHide = function () {
        $j('#add-batch-sample-btn').hide();
    };

    // Reset the wizard when the modal is closed
    $j('#AddSamplesFromDataFileModal').on('hide.bs.modal', function () {
        samplesTable.rows().deselect();
        wizard.reset();
    });

    $j('#samples-select-data-file .selectable[data-role="seek-association-candidate"]').click(function () {
        var candidate = $j(this);
        candidate.spinner('add');
        $j.ajax('/data_files/'+$j(this).data('associationId')+'/samples_table', {
                success: function (data) {
                    $j('#data-file-samples-table').html(data);
                    initSamplesTable();
                    wizard.step(2).unlock();
                    wizard.gotoStep(2);
                    candidate.spinner('remove');
                }
            }
        );

        return false;
    })
});
