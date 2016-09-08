/**
 * User: quyen
 * Date: 10/5/12
 * Time: 1:12 PM
 * To change this template use File | Settings | File Templates.
 */
function detect_browser(){
    var browser = new Object();
    browser.name  = navigator.appName;
    browser.fullVersion  = ''+parseFloat(navigator.appVersion);
    browser.majorVersion = parseInt(navigator.appVersion,10);
    var nVer = navigator.appVersion;
    var nAgt = navigator.userAgent;
    var nameOffset,verOffset,ix;

    // In Opera, the true version is after "Opera" or after "Version"
    if ((verOffset=nAgt.indexOf("Opera"))!=-1) {
        browser.name = "Opera";
        browser.fullVersion = nAgt.substring(verOffset+6);
        if ((verOffset=nAgt.indexOf("Version"))!=-1)
            browser.fullVersion = nAgt.substring(verOffset+8);
    }
    // In MSIE, the true version is after "MSIE" in userAgent
    else if ((verOffset=nAgt.indexOf("MSIE"))!=-1) {
        browser.name = "Microsoft Internet Explorer";
        browser.fullVersion = nAgt.substring(verOffset+5);
    }
    // In Chrome, the true version is after "Chrome"
    else if ((verOffset=nAgt.indexOf("Chrome"))!=-1) {
        browser.name = "Chrome";
        browser.fullVersion = nAgt.substring(verOffset+7);
    }
    // In Safari, the true version is after "Safari" or after "Version"
    else if ((verOffset=nAgt.indexOf("Safari"))!=-1) {
        browser.name = "Safari";
        browser.fullVersion = nAgt.substring(verOffset+7);
        if ((verOffset=nAgt.indexOf("Version"))!=-1)
            browser.fullVersion = nAgt.substring(verOffset+8);
    }
    // In Firefox, the true version is after "Firefox"
    else if ((verOffset=nAgt.indexOf("Firefox"))!=-1) {
        browser.name = "Firefox";
        browser.fullVersion = nAgt.substring(verOffset+8);
    }
    // In most other browsers, "name/version" is at the end of userAgent
    else if ( (nameOffset=nAgt.lastIndexOf(' ')+1) <
        (verOffset=nAgt.lastIndexOf('/')) )
    {
        browser.name = nAgt.substring(nameOffset,verOffset);
        browser.fullVersion = nAgt.substring(verOffset+1);
        if (browser.name.toLowerCase()==browser.name.toUpperCase()) {
            browser.name = navigator.appName;
        }
    }
    // trim the fullVersion string at semicolon/space if present
    if ((ix=browser.fullVersion.indexOf(";"))!=-1)
        browser.fullVersion=browser.fullVersion.substring(0,ix);
    if ((ix=browser.fullVersion.indexOf(" "))!=-1)
        browser.fullVersion=browser.fullVersion.substring(0,ix);

    browser.majorVersion = parseInt(''+browser.fullVersion,10);
    if (isNaN(browser.majorVersion)) {
        browser.fullVersion  = ''+parseFloat(navigator.appVersion);
        browser.majorVersion = parseInt(navigator.appVersion,10);
    }
    return browser;
}

function isCanvasSupportBrowser(){
    var test_canvas = document.createElement("canvas"); //try and create sample canvas element
    var canvas_check=(test_canvas.getContext)? true : false; //check if object supports getContext() method, a method of the canvas element
    return canvas_check;
}

function isIEVersionSupported(min_support_version){
    var browser = detect_browser();
    if (browser.name == 'Microsoft Internet Explorer' && browser.majorVersion < min_support_version){
        return false;
    }else
        return true;
}