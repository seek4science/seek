var ExtendedMetadataType = {
    updateJobStatusDisplay: function() {
        var containerFluidDiv = $j("#content .container-fluid");
        if (!$j("#notice_flash").length) {
            containerFluidDiv.prepend('<div id="notice_flash" class="alert-success" role="alert"></div>');
        }
        var noticeFlashDiv = $j("#notice_flash");
        noticeFlashDiv.addClass('alert alert-success');
        noticeFlashDiv.html('Job completed !');
        noticeFlashDiv.show();
    },

    addNewMarker: function(id, type) {
        var isNested = (type === "ExtendedMetadata");

        $j("#nested-tab, #nested-tab").parent().toggleClass("active", isNested);
        $j("#nested-metadata-table").toggleClass("active in", isNested);
        $j("#top-level-tab, #top-level-tab").parent().toggleClass("active", !isNested);
        $j("#top-level-metadata-table").toggleClass("active in", !isNested);

        var table = isNested ? $j("#nested-metadata-table") : $j("#top-level-metadata-table");
        table.find("tbody tr:first td:first").append(' <sup style="color:red; font-weight:bold; font-size: 12px">new</sup>');
    },

    initializeNoticeFlash: function() {
        var noticeFlashDiv = $j("#notice_flash");
        noticeFlashDiv.removeClass('alert-success').addClass('alert-warning').append('<div>Extraction Processing ... <img src="/assets/ajax-loader.gif"></div>').show();
    },

    showErrorAndHideNotice: function() {
        $j('#emt-error-message').css('display', 'block');
        $j('#notice_flash').css('display', 'none');
    }
};