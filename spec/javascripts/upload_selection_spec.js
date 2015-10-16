//= require 'upload_selection'

describe("tab selection", function(){
    fixture.set("<ul class='nav nav-tabs' role='tablist'>" +
        "<li role='presentation' class='active'>" +
        "<a href='#local-file' aria-controls='local-file' role='tab' data-toggle='tab'>Local file</a>" +
        "</li>" +
        "<li role='presentation'>" +
        "<a href='#remote-url' aria-controls='remote-url' role='tab' data-toggle='tab'>Remote URL</a>" +
        "</li>" +
        "</ul>"
    );


    it("should select local file tab by default", function() {
        var active_tab_text = jQuery('li.active a')[0].text;
        expect(active_tab_text).to.equal('Local file');
    });
    it("should select remote url tab when it is clicked", function() {
        var remote_url_tab = jQuery('ul.nav-tabs li')[1];
        expect(remote_url_tab.class).not.to.equal('active');
        remote_url_tab.children[0].click();
        var active_tab_text = jQuery('li.active a')[0].text;
        expect(active_tab_text).to.equal('Remote URL');
    });
});