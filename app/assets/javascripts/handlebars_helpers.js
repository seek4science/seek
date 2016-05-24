Handlebars.registerHelper('toJSON', function(object){
    return new Handlebars.SafeString(JSON.stringify(object));
});

Handlebars.registerHelper("inc", function(value){
    return parseInt(value) + 1;
});
