function toggleDynamicMenu(element) {

    if ($(element).visible()) {

    }
    else {
        Event.observe(document, 'click', function (event) {
            switch (event.element().id) {
                case element:
                    //ignore
                    break;
                default:
                    if ($(element).visible()) {
                        toggleDynamicMenu(element);
                    }
                    break;
            }
        });
    }

    Effect.toggle(element,'blind',{duration:0.1});


}
