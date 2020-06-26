Handlebars.registerHelper('toJSON', function(object){
    return new Handlebars.SafeString(JSON.stringify(object));
});

Handlebars.registerHelper("inc", function(value){
    return parseInt(value) + 1;
});

Handlebars.registerHelper('checkPrivilege', function(permission, accessType){
    return parseInt(permission.access_type) == parseInt(accessType) ? ' checked=checked' : '';
});

Handlebars.registerHelper('truncate', function (str, len) { // taken from https://gist.github.com/TastyToast/5053642
    if (str.length > len && str.length > 0) {
        var new_str = str + " ";
        new_str = str.substr (0, len);
        new_str = str.substr (0, new_str.lastIndexOf(" "));
        new_str = (new_str.length > 0) ? new_str : str.substr (0, len);

        return new Handlebars.SafeString ( new_str +'...' );
    }
    return str;
});

Handlebars.registerHelper('I18n', function (str) {
        if (I18n !== undefined) {
            str = I18n.t(str);
        }

        return str;
    }
);

Handlebars.registerHelper('downcase', function (str) { return str.toLowerCase(); });
