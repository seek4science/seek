describe('jstree function', function() {
    beforeEach(function() {
        let mock_data = [{
            "text": "Project",
            "state": { "separate": { 'label': 'Projects' }, },
            "children": [{ "text": "Presentations", "count": '0', "children": [{ "text": "Proposals", "count": '0', }] }, {
                "text": "Investigation",
                "state": { "separate": { 'label': 'Investigations', 'action': '#' } },
                "children": [{ "text": "Presentations ", "count": '0', "children": [{ "text": "Articles", "count": 4, }] }]
            }, ]
        }]

        this.tree = $j('<div id="treeview"><div id="html" ></div></div>');
        $j(document.body).append(this.tree);
        $j('#html').jstree({
            'core': {
                'data': mock_data
            }
        });
        console.log(document)
    });


    it('should insert the separators based on input data', function() {


        //  expect($j('#upload_type_selection ul.nav-tabs li.active a')).to.have.$text('Local file');
        // expect($j('#local-file')).to.have.$class('active');
        // expect($j('#remote-url')).to.not.have.$class('active');
    });

});