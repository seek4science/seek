$j(document).ready(function () {
    $j('[data-role="seek-wizard"]').each(function () {
        this.currentStep = 1;
        this.gotoStep = function (stepNo) {
            this.currentStep = stepNo;
            this.steps.hide();
            this.steps[this.currentStep - 1].show();
            $j('li', this.stepNav).removeClass('active');
            $j('li:eq('+(this.currentStep - 1)+')', this.stepNav).addClass('active');
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

        var wizard = this;
        var steps = $j('[data-role="seek-wizard-step"]', $j(this));
        var stepNav = $j('<ul class="seek-step-nav pagination">');
        this.steps = steps;
        this.stepNav = stepNav;

        steps.each(function (number, step) {
            var stepName = '';
            if($j(step).data('stepName'))
                stepName = ' - ' + $j(step).data('stepName');

            var stepEl = $j('<li><a href="#">Step ' + (number + 1) + stepName + '</a></li>');

            stepEl.click(function () {
                wizard.gotoStep(number + 1);
                return false;
            });
            stepNav.append(stepEl);
        });

        this.gotoStep(1);

        $j(this).prepend(stepNav);
    });
});
