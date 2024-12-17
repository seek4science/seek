var ROR_API_URL = "https://api.ror.org/organizations";

function extractRorId(rorUrl) {
    const regex = /https:\/\/ror\.org\/([^\/]+)/;
    const match = rorUrl.match(regex);
    if (match) {
        return match[1];
    } else {
        return null;
    }
}
function fetchRorData(rorId) {
    var url = ROR_API_URL + '/' + rorId;
    console.log(url);
    fetch(url)
        .then(response => {
            if (!response.ok) {
                return response.json().then(err => {
                    throw new Error(err.errors ? err.errors[0] : "Unknown error occurred");
                });
            }
            return response.json();
        })
        .then(data => {
            $j('#ror-response').html(JSON.stringify(data, undefined, 4));
            $j('#institution_title').val(data.name);
            $j('#institution_city').val(data.addresses[0]['city']);
            $j('#institution_country').val(data.country.country_name);
            $j('#institution_ror_id').val(extractRorId(data.id));
            $j('#institution_web_page').val(data.links?.[0] || 'N/A');
            $j('#ror-error-message').text('').hide();
            $j('#institution_ror_id').removeClass("field_with_errors");
            $j("#ror-error-message").closest(".form-group").removeClass("field_with_errors");
        })
        .catch(error => {
            $j('#ror-error-message').text(error.message).show();
            $j('#institution_ror_id').addClass("field_with_errors");
            $j("#ror-error-message").closest(".form-group").addClass("field_with_errors");
        });
}

$j(document).ready(function () {
    var $j = jQuery.noConflict();

    $j('#fetch-ror-data-with-id').on('click', function() {
            fetchRorData($j('#institution_ror_id').val());
        });

    $j('#ror_query_name .typeahead').typeahead({
            hint: true,
            highlight: true,
            minLength: 3
        },
        {
            limit: 50,
            async: true,
            source: function (query, processSync, processAsync) {
                var url = ROR_API_URL+'?query=' + encodeURIComponent(query);
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
                    'Fetching list ...',
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
        $j('#ror-response').html(JSON.stringify(suggestion, undefined, 4));
        $j('#institution_city').val(suggestion.addresses[0]['city']);
        $j('#institution_country').val(suggestion.country.country_name);
        $j('#institution_ror_id').val(extractRorId(suggestion.id));
        $j('#institution_web_page').val(suggestion.links[0]);
    });

    $j('#basic #name-01').bind('change', function() {
        $j('#ror-response').html('');
    });
});