describe('Permissions form', function() {
    beforeEach(function() {
        this.timeout(10000);
        MagicLamp.load('sharing/form');

        // This is necessary because script tags aren't processed when loading fixtures:
        this.permissionsTable = new Vue({
            el: '#permissions-table',
            data: {
                publicPermission: {
                    access_type: Sharing.accessTypes.accessible,
                    title: 'Public',
                    public: true,
                    mandatory: true },
                permissions: []
            }
        });
    });

    it('can change public access type', function() {
        expect(this.permissionsTable.publicPermission.access_type).to.equal(Sharing.accessTypes.accessible);

        click($j('#permissions-table tr.public-permission-row td.privilege-cell.no-access')[0]);

        expect(this.permissionsTable.publicPermission.access_type).to.equal(Sharing.accessTypes.noAccess);
    });
});

// `el.click()` is not supported by phantomJS, and JQuery's `trigger('click')` does not trigger Vue events
function click(el){
    var e = document.createEvent('Events');
    e.initEvent('click', true, false);
    el.dispatchEvent(e);
}
