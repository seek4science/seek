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

// ROR API source logic
function rorQuerySource(query, processSync, processAsync) {
    if (query.length < 3) {
        return processAsync([]); // Trigger only for 3+ characters
    }
    var url = ROR_API_URL + '?query=' + encodeURIComponent(query);
    return $j.ajax({
        url: url,
        type: 'GET',
        dataType: 'json',
        success: function (json) {
            const orgs = json.items;
            return processAsync(orgs);
        }
    });
}

// Template for Local Institution suggestions
function localSuggestionTemplate(data) {
    return `
        <div>
            <strong>${data.text}</strong>
            <small>${data.hint || ''}</small>
        </div>`;
}

// Template for ROR suggestions
function rorSuggestionTemplate(data) {
    var altNames = "";
    if (data.aliases.length > 0) {
        altNames += data.aliases.join(", ") + ", ";
    }
    if (data.acronyms.length > 0) {
        altNames += data.acronyms.join(", ") + ", ";
    }
    if (data.labels.length > 0) {
        data.labels.forEach(label => {
            altNames += label.label + ", ";
        });
    }
    altNames = altNames.replace(/,\s*$/, ""); // Trim trailing comma
    return `
    <div>
        <p>
            ${data.name}<br>
            <small>${data.types[0]}, ${data.country.country_name}<br>
            <i>${altNames}</i></small>
        </p>
    </div>`;
}


function initializeLocalInstitutions(endpoint = '/institutions/typeahead.json', cache = false) {

    const baseUrl = `${window.location.protocol}//${window.location.host}`;
    const fullUrl = `${baseUrl}${endpoint}`;
    console.log("Institutions URL: " + fullUrl);

    // Initialize and return the Bloodhound instance
    return new Bloodhound({
        datumTokenizer: Bloodhound.tokenizers.obj.whitespace('text'),
        queryTokenizer: Bloodhound.tokenizers.whitespace,
        prefetch: {
            url: fullUrl,
            cache: cache, // Use the provided cache option
            transform: function (response) {
                // Map the results array to the structure Bloodhound expects
                return response.results;
            }
        }
    });
}



$j(document).ready(function () {
    var $j = jQuery.noConflict();

    $j('#fetch-ror-data-with-id').on('click', function () {
        console.log("Fetching ROR data by ID...");
        fetchRorData($j('#institution_ror_id').val());
    });


    $j('#combined_typeahead .typeahead').typeahead(
        {
            hint: true,
            highlight: true,
            minLength: 1 // Start suggestions after typing at least 1 character
        },
        // First Dataset: Local Institutions
        {
            name: 'institutions',
            display: 'text', // Display the 'text' field in the dropdown
            source: initializeLocalInstitutions(), // Local data source
            templates: {
                header: '<div class="league-name">Institutions saved in SEEK</div>',
                suggestion: localSuggestionTemplate
            }
        },
        // Second Dataset: Remote ROR Query
        {
            name: 'ror-query',
            limit: 50,
            async: true,
            source: rorQuerySource,
            templates: {
                header: '<div class="league-name">Institutions fetched from ROR</div>',
                pending: '<div class="empty-message">Fetching from ROR API ...</div>',
                suggestion: rorSuggestionTemplate
            },
            display: function (data) {
                return data.name;
            },
            value: function (data) {
                return data.identifier;
            }
        }
    ).on('typeahead:select', function (e, suggestion) {
        // Close the dropdown after selection
        $j('#combined_typeahead .typeahead').typeahead('close');
    });


    $j('#ror_query_name .typeahead').typeahead({
            hint: true,
            highlight: true,
            minLength: 3
        },
        {
            limit: 50,
            async: true,
            source: rorQuerySource,
            templates: {
                pending: [
                    '<div class="empty-message">',
                    'Fetching list ...',
                    '</div>'
                ].join('\n'),
                suggestion: rorSuggestionTemplate
            },
            display: function (data) {
                console.log("Fetching ROR data by name remotely...");
                return data.name;
            },
            value: function (data) {
                return data.identifier;
            }
        });

    $j('#combined_typeahead .typeahead').bind('typeahead:select', function (ev, data) {
        if (data.hasOwnProperty("text")) {
            $j('#institution_title').val(data.text);
            $j('#institution_id').val(data.id);
            $j('#institution_ror_id').val(data.ror_id);
            $j('#institution_city').val(data.city);
            $j('#institution_country').val(data.country_name);
            $j('#institution_web_page').val(data.web_page);
        }
        else
        {
            $j('#institution_title').val(data.name);
            $j('#institution_ror_id').val(data.id);
            $j('#institution_city').val(data.addresses[0]['city']);
            $j('#institution_country').val(data.country.country_name);
            $j('#institution_ror_id').val(extractRorId(data.id));
            $j('#institution_web_page').val(data.links[0]);
        }


    });

    $j('#ror_query_name .typeahead').bind('typeahead:select', function (ev, suggestion) {
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