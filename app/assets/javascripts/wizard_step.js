var Wizards = {};

Wizards.Wizard = function (element) {
    this.steps = [];
    this.currentStep = null;
    this.element = element;
    this.complete = function () {};

    var wizard = this;
    $j('[data-role="seek-wizard-step"]', this.element).each(function (index, stepElement) {
        wizard.steps.push(new Wizards.Step(index + 1, $j(stepElement), wizard));
    });

    $j('[data-role="seek-wizard-nav"]', this.element).append(HandlebarsTemplates['wizard/nav']({ steps: wizard.steps }));

    $j('[data-role="seek-wizard-nav"] li a', this.element).click(function () {
        var stepNo = parseInt($j(this).data('step'));

        if(wizard.step(stepNo).unlocked)
            wizard.gotoStep(stepNo);

        return false;
    });
    $j('[data-role="seek-wizard-prev-btn"]', this.element).click(function () {
        wizard.lastStep();
        return false;
    });

    $j('[data-role="seek-wizard-next-btn"]', this.element).click(function () {
        wizard.nextStep();
        return false;
    });

    this.gotoStep(1);
};

Wizards.Wizard.prototype.step = function (number) {
    return this.steps[number - 1];
};

Wizards.Wizard.prototype.gotoStep = function (number) {
    for(var i = 0; i < this.steps.length; i++)
        this.steps[i].deactivate();

    if(this.step(number)) {
        this.currentStep = this.step(number);
        this.step(number).activate();
        this.updateNav();
        return true;
    } else
        return false;
};
Wizards.Wizard.prototype.nextStep = function () {
    var next = this.currentStep.number + 1;

    if(next > this.steps.length)
        return false;

    this.gotoStep(next);
};
Wizards.Wizard.prototype.lastStep = function () {
    var last = this.currentStep.number - 1;

    if(last < 1)
        return false;

    this.gotoStep(last);
};
Wizards.Wizard.prototype.updateNav = function () {
    // Highlight breadcrumb
    $j('[data-role="seek-wizard-nav"] li', this.element).removeClass('active');
    $j('[data-role="seek-wizard-nav"] li a[data-step="'+this.currentStep.number+'"]', this.element).parent().addClass('active');

    for(var i = 0; i < this.steps.length; i++) {
        if(!this.steps[i].unlocked) {
            $j('[data-role="seek-wizard-nav"] li a[data-step="'+this.steps[i].number+'"]', this.element).parent().addClass('disabled');
        } else {
            $j('[data-role="seek-wizard-nav"] li a[data-step="'+this.steps[i].number+'"]', this.element).parent().removeClass('disabled');
        }
    }

    // Show hide next/prev buttons
    var prevBtn =  $j('[data-role="seek-wizard-prev-btn"]', this.element);
    var nextBtn =  $j('[data-role="seek-wizard-next-btn"]', this.element);
    if(this.currentStep.number == 1 ||
        (this.step(this.currentStep.number - 1) && !this.step(this.currentStep.number - 1).unlocked))
        prevBtn.hide();
    else
        prevBtn.show();

    if(this.currentStep.number == this.steps.length ||
        (this.step(this.currentStep.number + 1) && !this.step(this.currentStep.number + 1).unlocked))
        nextBtn.hide();
    else
        nextBtn.show();
};
Wizards.Wizard.prototype.reset = function () {
    for(var i = 0; i < this.steps.length; i++)
        this.steps[i].lock();

    this.gotoStep(1);
};

Wizards.Step = function (number, element, wizard) {
    this.number = number;
    this.unlocked = false;
    this.wizard = wizard;
    this.element = element;
    this.name = this.element.data('stepName');
    this.onShow = function () {};
    this.onHide = function () {};
};

Wizards.Step.prototype.unlock = function () { this.unlocked = true; this.wizard.updateNav(); };
Wizards.Step.prototype.lock = function () { this.deactivate(); this.unlocked = false; this.wizard.updateNav(); };
Wizards.Step.prototype.activate = function () { this.unlock(); this.element.show(); this.onShow(); };
Wizards.Step.prototype.deactivate = function () { this.element.hide(); this.onHide(); };
