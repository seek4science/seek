var OpenBis = {

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
                beforeSend: function () {
                    $j('#openbis-file-view #contents').html("<span class='spinner'>&nbsp;</span>");
                }
            }
        );
    },

    refreshCache: function () {
        if (confirm('Are you sure you wish to refresh the cache?')) {
            var endpointId = $j(this).data('endpoint-id');
            var projectId = $j(this).data('project-id');
            var path = '/projects/' + projectId + '/openbis_endpoints/refresh_browse_cache'
            $j.ajax(path, {
                    method: 'POST',
                    data: {id: endpointId},
                    success: function (html) {
                        $j('#openbis-datasets #contents').html(html);
                    },
                    beforeSend: function () {
                        $j('#openbis-datasets #contents').html("<span class='large_spinner'></span>");
                    }
                }
            );
            //FIXME: this will possible happen before, or even during, the cache being cleared
            fetchCountForSpace(endpointId);
        }
    }

};