var ROR_API_URL = "https://api.ror.org/organizations?query=";

function extractRorId(rorUrl) {
    // Define the regular expression to match the ROR ID
    const regex = /https:\/\/ror\.org\/([^\/]+)/;

    // Try to match the URL with the regex
    const match = rorUrl.match(regex);

    // If a match is found, return the extracted ROR ID
    if (match) {
        return match[1];  // Return the captured ID
    } else {
        return null;  // Return null if no match is found
    }
}

$j(document).ready(function() {
    var $j = jQuery.noConflict();

    $j('#ror_query_name .typeahead').typeahead({
            hint: true,
            highlight: true,
            minLength: 3
        },
        {
            limit: 50,
            async: true,
            source: function (query, processSync, processAsync) {
                var url = ROR_API_URL + encodeURIComponent(query);
                return $j.ajax({
                    url: url,
                    type: 'GET',
                    dataType: 'json',
                    success: function (json) {
                        const orgs = json.items;
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
                    var altNames = "";
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

    $j('#ror_query_name .typeahead').bind('typeahead:select', function(ev, suggestion) {
        $j('#ror-id-01').html(JSON.stringify(suggestion, undefined, 4));
        $j('#institution_city').val(suggestion.addresses[0]['city']);
        $j('#institution_country').val(suggestion.country.country_name);
        $j('#institution_ror_id').val(extractRorId(suggestion.id));
        $j('#institution_web_page').val(suggestion.links[0]);
    });

    $j('#basic #name-01').bind('change', function() {
        $j('#ror-id-01').html('');
    });
});