var ExtendedMetadataType = {
    updateJobStatusDisplay: function() {
        var noticeFlashDiv = $j("#notice_flash");
        noticeFlashDiv.addClass('alert alert-success');
        noticeFlashDiv.html('Job completed !');
        noticeFlashDiv.show();
    },

    addNewMarker: function() {
        var table = $j("#top-level-metadata-table");
        var row = table.find("tbody tr:first");
        row.find("td:first").append(' <sup style="color:red; font-weight:bold; font-size: 12px">new</sup>');
    },

    initializeNoticeFlash: function() {
        var noticeFlashDiv = $j("#notice_flash");
        noticeFlashDiv.removeClass('alert-success').addClass('alert-warning').append('<div>Extraction Processing ... <img src="/assets/ajax-loader.gif"></div>').show();

        var containerFluidDiv = $j("#content .container-fluid");

        if ($j("#notice_flash").length === 0) {
            containerFluidDiv.prepend('<div id="notice_flash" class="alert-success" role="alert"></div>');
        }
    },

    showErrorAndHideNotice: function() {
        $j('#emt-error-message').css('display', 'block');
        $j('#notice_flash').css('display', 'none');
    }
};