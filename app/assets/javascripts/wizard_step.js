$j(document).ready(function () {
    $j('[data-role="seek-wizard"]').each(function () {
        console.log("hi");
        var wizard = $j(this);
        var steps = $j('[data-role="seek-wizard-step"]', $j(this));
        var stepNav = $j('<ul class="seek-step-nav pagination">');

        steps.each(function (number, step) {
            var stepEl = $j('<li><a href="#">Step ' + (number+1) +'</a></li>');
            if(number == 0) {
                stepEl.addClass('active');
                step.show();
            } else {
                step.hide();
            }

            stepEl.click(function () {
                $j(this).siblings().removeClass('active');
                $j(this).addClass('active');
                steps.hide();
                $j(step).show();
                return false;
            });
            stepNav.append(stepEl);
        });

        $j(this).prepend(stepNav);
    });
});
