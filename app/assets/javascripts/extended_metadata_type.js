var ExtendedMetadataType = {

    addNewMarker: function(new_id, type) {
        var isNested = (type === "ExtendedMetadata");
        $j("#nested-tab, #nested-tab").parent().toggleClass("active", isNested);
        $j("#nested-metadata-table").toggleClass("active in", isNested);
        $j("#top-level-tab, #top-level-tab").parent().toggleClass("active", !isNested);
        $j("#top-level-metadata-table").toggleClass("active in", !isNested);

        var table = isNested ? $j("#nested-metadata-table") : $j("#top-level-metadata-table");
        table.find("tbody td#" + new_id).append(' <sup style="color:red; font-weight:bold; font-size: 12px">new</sup>');
    }
};