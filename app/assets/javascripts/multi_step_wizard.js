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
    lastStep: function () {
        var steps = $j('.multi-step-block').map(function () {
            return this.id
        }).toArray();
        var lastId = steps.sort()[steps.length - 1];
        return lastId.replace('step-', '');
    },
    numberOfSteps:function() {
      return $j('.multi-step-block').length;
    },
    renderProgressIndicators: function() {
        var n = MultiStepWizard.numberOfSteps();

        $j('.multi-step-progress-indicator').each(function (index) {
            for (var i=0;i<n;i++) {
                if (i == index) {
                    $j(this).append($j("<span/>").attr({class:'multi-step-progress-indicator-icon'}));
                }
                else {
                    $j(this).append($j("<span/>").attr({class:'multi-step-progress-indicator-icon'}).css({opacity:0.2}));
                }

            }
        });
    }

};

$j(document).ready(function () {
    MultiStepWizard.jumpToStep(1);

    MultiStepWizard.renderProgressIndicators();

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

        //ignore keypress events if in a text box
        if (document.activeElement != null) {
            if (document.activeElement.type=="text" || document.activeElement.type == "textarea") {
                console.log("returning");
                return;
            }
        }

        if (e.keyCode==39) {
            MultiStepWizard.nextStep();
        }

        if (e.keyCode==37) {
            MultiStepWizard.prevStep();
        }

        if (e.keyCode==35) {
            MultiStepWizard.jumpToEnd();
        }

        if (e.keyCode==36) {
            MultiStepWizard.jumpToStart();
        }
    });
});