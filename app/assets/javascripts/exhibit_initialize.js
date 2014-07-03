if (window.location.href.match('search') == null){
    Exhibit.jQuery(document).ready(initializationFunction);
}else if (Exhibit.SelectionState.currentAssetType == "All"){
    Exhibit.jQuery(document).ready(initializationFunction);
}
