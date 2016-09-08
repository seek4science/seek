/**
https://github.com/bootstrap-tagsinput/bootstrap-tagsinput/issues/331
mentions that there is no typeahead('val','') function
https://github.com/bootstrap-tagsinput/bootstrap-tagsinput/issues/436
the following adds the fix
*/
jQuery.extend(jQuery.fn.typeahead.Constructor.prototype, {
    val: function (value) {
        setTimeout(function () {
            this.$element.val(value);
        }.bind(this));
    }
});