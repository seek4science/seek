var OpenBis = {

    showBrowseWaitingMessage: function () {
        $j('#openbis-datasets #contents').html($j('#waiting-for-items').clone().show());
    },

    showBrowseErrorMessage: function (element_id) {
        $j(element_id).html($j('#something-went-wrong').clone().show());
    },

    showFiles: function () {
        var permId = $j(this).data('perm-id');
        var endpointId = $j(this).data('endpoint-id');
        var dataFileId = $j(this).data('datafile-id');
        var projectId = $j(this).data('project-id');
        var path = '/projects/' + projectId + '/openbis_endpoints/show_dataset_files'

        $j.ajax(path, {
                data: {id: endpointId, data_file_id: dataFileId, perm_id: permId},
                success: function (html) {
                    $j('#openbis-file-view #contents').html(html);
                },
                error: function(jqXHR,textStatus,errorThrown) {
                    OpenBis.showBrowseErrorMessage('#openbis-file-view #contents');
                },
                beforeSend: function () {
                    $j('#openbis-file-view #contents').html("<span class='spinner'>&nbsp;</span>");
                }
            }
        );
    },

    refreshMetadataStore: function () {
        if (confirm('Are you sure you wish to refresh the metadata?')) {
            var endpointId = $j(this).data('endpoint-id');
            var projectId = $j(this).data('project-id');
            var path = '/projects/' + projectId + '/openbis_endpoints/refresh_metadata_store'
            $j.ajax(path, {
                    method: 'POST',
                    data: {id: endpointId},
                    success: function (html) {
                        $j('#openbis-datasets #contents').html(html);
                    },
                    error: function(jqXHR,textStatus,errorThrown) {
                        OpenBis.showBrowseErrorMessage('#openbis-datasets #contents');
                    },
                    beforeSend: function () {
                        OpenBis.showBrowseWaitingMessage();
                    }
                }
            );
        }
    },

    fetchItemsForBrowseSpace: function (spaceId, projectId) {
        var path = '/projects/' + projectId + '/openbis_endpoints/show_items'
        $j.ajax(path, {
                data: {id: spaceId},
                success: function (html) {
                    $j('#openbis-datasets #contents').html(html);
                },
                error: function(jqXHR,textStatus,errorThrown) {
                    OpenBis.showBrowseErrorMessage('#openbis-datasets #contents');
                },
                beforeSend: function () {
                    OpenBis.showBrowseWaitingMessage();
                }
            }
        );
    },


    browseEndpointChanged: function () {
        var selected = $j('#select-endpoints option:selected')
        var endpointId = selected.val();
        var projectId = selected.data('project-id');
        if (endpointId.trim()) {
            OpenBis.fetchItemsForBrowseSpace(endpointId, projectId);
        }
        else {
            $j('#openbis-datasets #contents').html('');
        }
    }

};