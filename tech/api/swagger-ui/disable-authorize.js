const DisableAuthorizePlugin = function() {
    return {
	wrapComponents: {
	    authorizeBtn: () => () => null
	}
    };
};
