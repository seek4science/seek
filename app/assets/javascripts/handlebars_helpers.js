Handlebars.registerHelper('toJSON', function(object){
    return new Handlebars.SafeString(JSON.stringify(object));
});

Handlebars.registerHelper("inc", function(value){
    return parseInt(value) + 1;
});

Handlebars.registerHelper('checkPrivilege', function(permission, accessType){
    return parseInt(permission.access_type) == parseInt(accessType) ? ' checked=checked' : '';
});
