Handlebars.registerHelper('toJSON', function(object){
    return new Handlebars.SafeString(JSON.stringify(object));
});
