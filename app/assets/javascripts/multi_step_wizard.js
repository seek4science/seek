var MultiStepWizard = {
    currentStep: 1,
    nextStep: function() {
        if (this.currentStep.toString()!=MultiStepWizard.lastStep()) {
            this.jumpToStep(this.currentStep+1);
        }
    },
    prevStep: function() {
        if (this.currentStep>1) {
            this.jumpToStep(this.currentStep-1);
        }
    },
    jumpToStep: function(step) {
        $j('#step-' + this.currentStep).hide();
        this.currentStep = step;
        $j('#step-' + this.currentStep).fadeIn();
    },
    jumpToStart: function() {
        this.jumpToStep(1);
    },
    jumpToEnd: function() {
      this.jumpToStep(this.lastStep());
    },
    lastStep: function() {
        var lastId = $j('.multi-step-block').map(function(){return this.id}).toArray().sort().last();
        return lastId.gsub('step-','');
    },
    numberOfSteps:function() {
      return $j('.multi-step-block').length;
    },
    renderProgressBlobs: function() {
        var n = MultiStepWizard.numberOfSteps();

        $j('.multi-step-progress-blobs').each(function (index) {
            for (var i=0;i<n;i++) {
                if (i == index) {
                    $j(this).append($j("<span/>").attr({class:'glyphicon glyphicon-apple'}));
                }
                else {
                    $j(this).append($j("<span/>").attr({class:'glyphicon glyphicon-apple'}).css({opacity:0.2}));
                }

            }
        });
    }

};

$j(document).ready(function () {
    MultiStepWizard.jumpToStep(1);

    MultiStepWizard.renderProgressBlobs();

    $j('.multi-step-next-button').click(function () {
        MultiStepWizard.nextStep();
        return false;
    });

    $j('.multi-step-back-button').click(function () {
        MultiStepWizard.prevStep();
        return false;
    });

    $j('.multi-step-end-button').click(function () {
        MultiStepWizard.jumpToEnd();
        return false;
    });

    $j('.multi-step-start-button').click(function () {
        MultiStepWizard.jumpToStart();
        return false;
    });

    $j(document).keydown(function(e) {
        if (e.keyCode==39) {
            MultiStepWizard.nextStep();
        }

        if (e.keyCode==37) {
            MultiStepWizard.prevStep();
        }

        if (e.keyCode==35) {
            MultiStepWizard.jumpToEnd();
        }
    });
});