function populateAuthors(select, authors) {
    let authorArray = [];

    // Check if authors come from PubMed XML
    if (authors.AuthorList) {
        const list = Array.isArray(authors.AuthorList.Author)
            ? authors.AuthorList.Author
            : [authors.AuthorList.Author];

        authorArray = list.map(a => ({ given: a.ForeName, family: a.LastName }));
    } else if (Array.isArray(authors)) {
        // Already in {given, family} format
        authorArray = authors;
    } else {
        console.warn("Unsupported author format:", authors);
        return;
    }

    // Populate Select2
    authorArray.forEach(author => {
        const fullName = `${author.given} ${author.family}`;
        let option = select.find(`option[value="${fullName}"]`);
        if (!option.length) {
            const newOption = new Option(fullName, fullName, true, true);
            select.append(newOption);
        } else {
            option.prop('selected', true);
        }
    });

    // Remove empty option and trigger update
    select.find('option[value=""]').remove();
    select.trigger('change');
}



function transferProjectIds() {
    // need to transfer project ids from the project selector to the hidden element in the 'register' form
    var selectedProjects = Sharing.projectsSelector.selected.map(function (n) {
        return n.id
    });

    var registerForm = $j('form#new_publication');

    for (var i = 0; i < selectedProjects.length; i++) {
        var element = "<input multiple='multiple' value='" + selectedProjects[i] + "' type='hidden' name='publication[project_ids][]' id='publication_project_ids'>";
        registerForm.append(element);
    }
}


function retrieveFromCrossref(e) {
    e.preventDefault(); // prevent the default form submit action

    var doi = $j('#publication_doi').val();
    doi = doi.replace(/^(https?:\/\/)?(dx\.)?doi\.org/, '');

    $j.ajax({
        url: 'https://doi.org/' + doi,
        accepts: { 'citeproc': "application/vnd.citationstyles.csl+json" },
        dataType: 'json',
        success: function(data, textStatus, jqXHR) {
            $j('#publication_doi').parents('.form-group').removeClass('has-error');
            $j('#publication_doi').parents('.form-group').addClass('has-success');
            $j('#crossref_id').val(data.DOI);
            $j('#publication_title').val(data.title);
            $j('#publication_publisher').val(data.publisher);
            $j('#publication_url').val(data.URL);

            const published_data = data.created;
            const year = published_data["date-parts"][0][0];
            const month = published_data["date-parts"][0][1];
            const day = published_data["date-parts"][0][2];
            const date_published = `${year}-${month}-${day}`;
            console.log("Published date:", date_published);
            $j('#publication_published_date').val(date_published);

            if (typeof data["abstract"] !== 'undefined') {
                var regex = /(<([^>]+)>)/ig;
                var result = data["abstract"].replace(regex, "").slice(9);
                $j('#publication_abstract').val(result);
            }

            let citation = data["container-title"] || "";

            if (typeof data["volume"] !== 'undefined') {
                citation += ', ' + data["volume"];
            }

            if (typeof data["issue"] !== 'undefined') {
                citation += '(' + data["issue"] + ')';
            }

            if (typeof data["page"] !== 'undefined') {
                citation += ':' + data["page"];
            }

            $j('#publication_citation').val(citation);
            populateAuthors($j('#publication_publication_authors'), data.author);
        },
        statusCode: {
            204: function() { console.log("DOI: " + doi + " The request was OK but there was no metadata available."); },
            404: function() { console.log("DOI: " + doi + " The DOI requested doesn't exist."); },
            406: function() { console.log("DOI: " + doi + " Can't serve any requested content type."); }
        },
        error: function() {
            $j('#publication_doi').parents('.form-group').removeClass('has-success');
            $j('#publication_doi').parents('.form-group').addClass('has-error');
        }
    });
}

function retrieveFromPubmed(e) {
    e.preventDefault(); // prevent the default form submit action
    var pubmedid = $j('#publication_pubmed_id').val();
    $j.ajax({
        url: 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi',
        data: {
            'db': 'pubmed',
            'id': pubmedid,
            'retmode': 'xml',
            'retmax': 1
        },
        dataType: 'xml',
        success: function(data, textStatus, jqXHR) {
            $j('#publication_pubmed_id').parents('.form-group').removeClass('has-error');
            $j('#publication_pubmed_id').parents('.form-group').addClass('has-success');
            var doc = $j(data);

            var doi_elem = $j(data).find('PubmedArticleSet > PubmedArticle > PubmedData > ArticleIdList > ArticleId[IdType="doi"]');
            if (doi_elem.length != 0) {
                $j('#publication_doi').val(doi_elem.html());
            }
            var article = $j(data).find('PubmedArticleSet > PubmedArticle > MedlineCitation > Article');
            var title_elem = article.find('ArticleTitle');
            if (title_elem.length != 0) {
                $j('#publication_title').val(title_elem.html());
            }
            var abstract_elem = article.find('Abstract > AbstractText');
            if (abstract_elem.length != 0) {
                $j('#publication_abstract').val(abstract_elem.html());
            }
            var journal_elem = article.find('Journal > Title');
            if (journal_elem.length != 0) {
                $j('#publication_journal').val(journal_elem.html());
            }

            if (!$j('#publication_citation').val()) {
                var journalIssue_Title = article.find('Journal > Title');
                var publication_citation = journalIssue_Title.html();

                if (article.find('Journal > JournalIssue > Volume').length > 0) {
                    publication_citation += ',' + article.find('Journal > JournalIssue > Volume').html();
                }

                if (article.find('Journal > JournalIssue > Issue').length > 0) {
                    publication_citation += '(' + article.find('Journal > JournalIssue > Issue').html() + ')';
                }

                if (article.find('Pagination > MedlinePgn').length > 0) {
                    publication_citation += ':' + article.find('Pagination > MedlinePgn').html();
                }
                $j('#publication_citation').val(publication_citation);
            }

            var published_date1 = article.find('Journal > JournalIssue > PubDate');
            var published_date2 = article.find('ArticleDate');

            if (published_date1.find('Year').length == 0 ||
                published_date1.find('Month').length == 0 ||
                published_date1.find('Day').length == 0) {

                var date_published = published_date2.find('Year').html() + "-" + published_date2.find('Month').html() + "-" + published_date2.find('Day').html();
                $j('#publication_published_date').val(date_published);

            } else {
                var date_published = published_date1.find('Year').html() + "-" + published_date1.find('Month').html() + "-" + published_date1.find('Day').html();
                $j('#publication_published_date').val(date_published);
            }

            var authors = [];
            article.find('AuthorList > Author').each(function() {
                var given = $j(this).find('ForeName').text().trim();
                var family = $j(this).find('LastName').text().trim();

                if (given || family) {
                    authors.push({ given: given, family: family });
                }
            });

            var select = $j('#publication_publication_authors');
            populateAuthors(select, authors);
        },
        error: function() {
            $j('#publication_pubmed_id').parents('.form-group').removeClass('has-success');
            $j('#publication_pubmed_id').parents('.form-group').addClass('has-error');
        }
    });
}


