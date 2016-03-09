$j(document).ready(function () {
    $j('[data-role="seek-wizard"]').each(function (index, wizard) {
        this.currentStep = 1;

        this.gotoStep = function (stepNo) {
            this.currentStep = stepNo;
            this.steps.hide();
            this.steps[this.currentStep - 1].show();

            // Highlight breadcrumb
            $j('[data-role="seek-wizard-nav"] li', $j(this)).removeClass('active');
            $j('[data-role="seek-wizard-nav"] li:eq('+(this.currentStep - 1)+')', $j(this)).addClass('active');

            // Show hide next/prev buttons
            if(this.currentStep == 1)
                $j('[data-role="seek-wizard-prev-btn"]').hide();
            else
                $j('[data-role="seek-wizard-prev-btn"]').show();

            if(this.currentStep == this.steps.length)
                $j('[data-role="seek-wizard-next-btn"]').hide();
            else
                $j('[data-role="seek-wizard-next-btn"]').show();
        };
        this.nextStep = function () {
            if(++this.currentStep > this.steps.length)
                this.currentStep = this.steps.length;
            this.gotoStep(this.currentStep);
        };
        this.lastStep = function () {
            if(--this.currentStep < 1)
                this.currentStep = 1;

            this.gotoStep(this.currentStep);
        };

        var steps = $j('[data-role="seek-wizard-step"]', $j(this));
        $j(this).prepend(HandlebarsTemplates['wizard/nav']({ steps: steps.map(function () { return $j(this).data('stepName') || ''; }).toArray() }));
        $j(this).append(HandlebarsTemplates['wizard/buttons']());
        this.steps = steps;

        $j('[data-role="seek-wizard-nav"] li a', $j(wizard)).click(function () {
            wizard.gotoStep($j(this).data('step'));
            return false;
        });
        $j('[data-role="seek-wizard-prev-btn"]', $j(wizard)).click(function () {
            wizard.lastStep();
        });

        $j('[data-role="seek-wizard-next-btn"]', $j(wizard)).click(function () {
            wizard.nextStep();
        });

        this.steps = steps;

        this.gotoStep(1);
    });
});
