function toggleDynamicMenu(element) {

    function documentClickedHandler(event) {
        if (!event.element().hasClassName("dynamic_menu_li")) {
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
        }
    }

    if ($(element).visible()) {
        Event.stopObserving(document,'click',documentClickedHandler);
    }
    else {
        Event.observe(document, 'click', documentClickedHandler);
    }

    Effect.toggle(element,'blind',{duration:0.1});

}


