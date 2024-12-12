var ROR_API_URL = "https://api.ror.org/organizations?query="

$('#basic .typeahead, #basic-department .typeahead, #addl-info .typeahead').typeahead({
    hint: true,
    highlight: true,
    minLength: 3
  },
  {
    limit: 50,
    async: true,
    source: function (query, processSync, processAsync) {
        url = ROR_API_URL + encodeURIComponent(query);
        return $.ajax({
            url: url,
            type: 'GET',
            dataType: 'json',
            success: function (json) {
                orgs = json.items
                alert("orgs: " + orgs)
                return processAsync(orgs);
            }
        });
    },
    templates: {
      pending: [
        '<div class="empty-message">',
          'Fetching organizations list',
        '</div>'
      ].join('\n'),
      suggestion: function (data) {
          altNames = ""
          if(data.aliases.length > 0) {
            for (let i = 0; i < data.aliases.length; i++){
                altNames += data.aliases[i] + ", ";
            }
          }
          if(data.acronyms.length > 0) {
            for (let i = 0; i < data.acronyms.length; i++){
                altNames += data.acronyms[i] + ", ";
            }
          }
          if(data.labels.length > 0) {
            for (let i = 0; i < data.labels.length; i++){
                altNames += data.labels[i].label + ", ";
            }
          }
          altNames = altNames.replace(/,\s*$/, "");
          return '<p>' + data.name + '<br><small>' + data.types[0] + ', ' + data.country.country_name + '<br><i>'+ altNames + '</i></small></p>';
      }
    },
    display: function (data) {
      return data.name;
    },
    value: function(data) {
      return data.identifier;
    }
});

$('#basic .typeahead').bind('typeahead:select', function(ev, suggestion) {
  console.log(suggestion)
  $('#ror-id-01').html(JSON.stringify(suggestion, undefined, 4));
});

$('#basic #name-01').bind('change', function() {
  $('#ror-id-01').html('');
});

$('#basic-department .typeahead').bind('typeahead:select', function(ev, suggestion) {
  console.log(suggestion)
  $('#city').val(suggestion.addresses[0]['city']);
  $('#country').val(suggestion.country.country_name);
  $('#ror-id-02').html(JSON.stringify(suggestion, undefined, 4));
});

$('#basic #name-02').bind('change', function() {
  $('#ror-id-02').html('');
});

$('#addl-info .typeahead').bind('typeahead:select', function(ev, suggestion) {
  console.log(suggestion)
  $('#city-03').val(suggestion.addresses[0]['city']);
  $('#country-03').val(suggestion.country.country_name);
  $('#ror-id-03').html(JSON.stringify(suggestion, undefined, 4));
});

$('#addl-info #name-03').bind('change', function() {
  $('#city-03').val('');
  $('#country-03').val('');
  $('#ror-id-03').html('');
});