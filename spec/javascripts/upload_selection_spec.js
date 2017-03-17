describe('tab selection', function(){
    beforeEach(function() {
        this.timeout(10000);
        MagicLamp.load('sops/new');
    });

    it('should select local file tab by default', function() {
        expect($j('#upload_type_selection ul.nav-tabs li.active a')).to.have.$text('Local file');
        expect($j('#local-file')).to.have.$class('active');
        expect($j('#remote-url')).to.not.have.$class('active');
    });

    it('should select remote url tab when it is clicked', function() {
        var remoteUrlTabLink = $j("#upload_type_selection ul.nav-tabs li a[href='#remote-url']");
        var remoteUrlTab = remoteUrlTabLink.parent();

        expect(remoteUrlTab).to.not.have.$class('active');

        remoteUrlTabLink.trigger('click');
        expect(remoteUrlTab.find("a[href='#remote-url']")).to.have.$text('Remote URL');
        expect($j('#local-file')).to.not.have.$class('active');
        expect($j('#remote-url')).to.have.$class('active');
    });
});
