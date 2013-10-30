(function ($) {
	$.fn.easyTabs = function () {
		return this.each(function(i, container) {
			$(this).find('> ul.easytabs-nav > li').click(function () {
				$(container).find('> .easytabs-pane').removeClass('active');
				$(container).find('> .easytabs-pane:eq(' +  $(this).index() + ')').addClass('active');
				$(this).siblings().removeClass('active');
				$(this).addClass('active');
			});
			// Show first tab by default
			$(this).find('> ul.easytabs-nav > li:eq(0)').addClass('active');
			$(this).find('> .easytabs-pane:eq(0)').addClass('active');
		});
	};
}( jQuery ));

