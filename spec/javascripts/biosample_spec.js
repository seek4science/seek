//= require 'biosample'

describe("Biosamples", function() {
    var sandbox;

    beforeEach(function() {
        // create a sandbox
        sandbox = sinon.sandbox.create();

        // stub some console methods
        sandbox.stub(Ajax, 'Request');
    });

    afterEach(function() {
        // restore the environment as it was before
        sandbox.restore();
    });


    it("makes an ajax request to get strains of selected organism", function () {
        strains_of_selected_organism(1,1,'strain_box');
        sinon.assert.calledOnce(Ajax.Request);
        sinon.assert.calledWith(Ajax.Request, "/biosamples/strains_of_selected_organism");
    });
});