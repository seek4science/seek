describe('jstree function', function () {
    before(function (done) {
        let mock_data = [{
            "text": "Project",
            "state": { "separate": { 'label': 'Projects' },'opened':true },
            "children": [{ "text": "Presentations", "count": '0', "children": [{ "text": "Proposals", "count": '0', }] }, {
                "text": "Investigation",
                "state": { "separate": { 'label': 'Investigations', 'action': '#' },'opened':true },
                "children": [{ "text": "Presentations ", "count": '0', "children": [{ "text": "Articles", "count": 4, }] }]
            },]
        }]

        this.tree = $j('<div id="treeview"><div id="jstree" ></div></div>');
        $j(document.body).append(this.tree);
        $j('#jstree').jstree({
            'core': {
                'data': mock_data
            }
        });

        var interval_id = setInterval(function () {
            if ($j("li#j1_1").length != 0) {
                clearInterval(interval_id)
                done();
            }
        }, 1000);

    });


    it('should insert the separators based on input data', function () {
        expect($j('#jstree ul')).to.have.$class('jstree-container-ul');
        expect($j('#jstree ul li p')).to.have.$class('separator');
    });

    it('should insert the badges', function () {
        expect($j('#jstree ul li ul li:first a span')).to.have.$class('badge');

    });

});