describe('Permissions form and projects selector', function() {
    beforeEach(function() {
        this.timeout(10000);
        MagicLamp.load('sops/edit');

        // This is necessary because script tags aren't processed when loading fixtures:
        this.permissionsTable = new Vue({
            el: '#permissions-table',
            data: {
                publicPermission: {
                    access_type: Sharing.accessTypes.accessible,
                    title: 'Public',
                    isPublic: true,
                    isMandatory: true },
                permissions: []
            }
        });

        this.projectsSelector = new Vue({
            el: '#project-selector',
            data: {
                possibilities: [{ id: 1, title: 'Project-1'}],
                selected: []
            },
            methods: {
                remove: function (project, index) {
                    this.possibilities.push(project);
                    this.selected.splice(index, 1);
                    Sharing.removePermissionForProject(project);
                }
            }
        });

        Sharing.permissionsTable = this.permissionsTable;
        Sharing.projectsSelector = this.projectsSelector;
    });

    it('renders a row for the public permission', function () {
        expect($j('#permissions-table tr.public-permission-row').length).to.equal(1);
        expect($j('#permissions-table tr.public-permission-row a.remove-button').length).to.equal(0);
        expect(parseInt($j('#permissions-table tr.public-permission-row:last input[type=radio]:checked').val())).to.equal(Sharing.accessTypes.accessible);
    });

    it('renders new rows for new permissions', function (done) { // Note the "done" here
        expect($j('#permissions-table tr.permission-row').length).to.equal(1);

        this.permissionsTable.permissions.push({ access_type: Sharing.accessTypes.editing,
            contributor_type: 'Person',
            contributor_id: 1 });

        Vue.nextTick(function () { // Need to check changes to the Vue DOM elements in this asynchronous function
            expect($j('#permissions-table tr.permission-row').length).to.equal(2);
            expect(parseInt($j('#permissions-table tr.permission-row:last input[type=radio]:checked').val())).to.equal(Sharing.accessTypes.editing);
            done();
        });
    });

    it('changes the public access type', function(done) {
        expect(this.permissionsTable.publicPermission.access_type).to.equal(Sharing.accessTypes.accessible);

        click($j('#permissions-table tr.public-permission-row td.privilege-cell.no-access')[0]);

        expect(this.permissionsTable.publicPermission.access_type).to.equal(Sharing.accessTypes.noAccess);

        Vue.nextTick(function () {
            expect(parseInt($j('#permissions-table tr.public-permission-row:last input[type=radio]:checked').val())).to.equal(Sharing.accessTypes.noAccess);
            done();
        });
    });

    it('decreases the public access type if the existing setting is clicked', function(done) {
        expect(this.permissionsTable.publicPermission.access_type).to.equal(Sharing.accessTypes.accessible);

        click($j('#permissions-table tr.public-permission-row td.privilege-cell.enabled')[0]);

        expect(this.permissionsTable.publicPermission.access_type).to.equal(Sharing.accessTypes.visible);

        Vue.nextTick(function () {
            expect(parseInt($j('#permissions-table tr.public-permission-row:last input[type=radio]:checked').val())).to.equal(Sharing.accessTypes.visible);
            done();
        });
    });

    it('deletes permission rows', function (done) {
        this.permissionsTable.permissions.push({ access_type: Sharing.accessTypes.editing,
            contributor_type: 'Person',
            contributor_id: 1 });

        this.permissionsTable.permissions.push({ access_type: Sharing.accessTypes.editing,
            contributor_type: 'Project',
            contributor_id: 2 });

        var permissionsTable = this.permissionsTable; // "this" context is lost in the function below
        Vue.nextTick(function () {
            expect(permissionsTable.permissions.length).to.equal(2);

            // Delete the last row (the Project permission)
            click($j('#permissions-table tr.permission-row:last a.remove-button')[0]);

            expect(permissionsTable.permissions.length).to.equal(1);
            expect(permissionsTable.permissions[0].contributor_id).to.equal(1);
            expect(permissionsTable.permissions[0].contributor_type).to.equal('Person');
            Vue.nextTick(function () {
                expect($j('#permissions-table tr.permission-row').length).to.equal(2); // 2 because it includes the public permission row
                done();
            });
        });
    });

    it('adds a project permission to the table', function (done) {
        expect(this.permissionsTable.permissions.length).to.equal(0);

        Sharing.addPermissionForProject({ id: 1, title: 'Project-1' });

        expect(this.permissionsTable.permissions.length).to.equal(1);
        expect(this.permissionsTable.permissions[0].contributor_id).to.equal(1);
        expect(this.permissionsTable.permissions[0].contributor_type).to.equal('Project');

        Vue.nextTick(function () {
            expect($j('#permissions-table tr.permission-row').length).to.equal(2); // 2 because it includes the public permission row
            done();
        });
    });
});

// `el.click()` is not supported by phantomJS, and JQuery's `trigger('click')` does not trigger Vue events
function click(el){
    var e = document.createEvent('Events');
    e.initEvent('click', true, false);
    el.dispatchEvent(e);
}
