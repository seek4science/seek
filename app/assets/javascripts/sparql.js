document.addEventListener('DOMContentLoaded', function() {
    // Get DOM elements
    const clearQueryBtn = document.getElementById('clear-query');
    const clearResultsBtn = document.getElementById('clear-results');
    const queryTextarea = document.getElementById('sparql_query');
    const copyBtn = document.getElementById('copy-query-url');

    if (clearQueryBtn && queryTextarea) {
        clearQueryBtn.addEventListener('click', function() {
            queryTextarea.value = '';
            queryTextarea.focus();
        });
    }

    if (clearResultsBtn && queryTextarea) {
        clearResultsBtn.addEventListener('click', function() {
            const resultsContainer = document.getElementById('sparql-results');
            if (resultsContainer) {
                resultsContainer.remove();
                queryTextarea.focus();
            }
        });
    }

    // Copy query URL to clipboard
    if (copyBtn && queryTextarea) {
        copyBtn.addEventListener('click', function () {
            const formatEl = document.querySelector('.sparql-format-select');
            const query = queryTextarea.value;
            const format = formatEl ? formatEl.value : '';

            const url = window.location.origin + '/sparql';
            const params = new URLSearchParams();
            if (query && query.trim() !== '') params.set('sparql_query', query);
            if (format) params.set('output_format', format);
            const fullUrl = url + (params.toString() ? '?' + params.toString() : '');


            if (navigator.clipboard && navigator.clipboard.writeText) {
                navigator.clipboard.writeText(fullUrl).then(function () {
                    const original = copyBtn.innerHTML;
                    copyBtn.innerHTML = '<i class="glyphicon glyphicon-copy"></i> Copied!';
                    setTimeout(function () {
                        copyBtn.innerHTML = original;
                    }, 2000);
                }).catch(function () {
                    alert("Sorry, but your browser doesn't support this feature.");
                });
            } else {
                alert("Sorry, but your browser doesn't support this feature.");
            }
        });
    }

    // allow tabs, instead of jumping to next element
    if (queryTextarea) {
        queryTextarea.addEventListener('keydown', function(e) {
            if (e.key === 'Tab') {
                e.preventDefault();
                const start = this.selectionStart;
                const end = this.selectionEnd;

                // set textarea value to: text before caret + tab + text after caret
                this.value = this.value.substring(0, start) +
                    "\t" + this.value.substring(end);

                // put caret at right position again
                this.selectionStart =
                    this.selectionEnd = start + 1;
            }
        });
    }


    // Auto-resize textarea
    if (queryTextarea) {
        function autoResize() {
            queryTextarea.style.height = 'auto';
            queryTextarea.style.height = Math.max(queryTextarea.scrollHeight, 200) + 'px';
        }

        queryTextarea.addEventListener('input', autoResize);
        autoResize(); // Initial resize
    }

    // Handle clicks on URI links to execute DESCRIBE queries
    document.addEventListener('click', function(e) {
        if (e.target.classList.contains('external-link')) {
            e.preventDefault(); // Prevent default link behavior
            
            const uri = e.target.href;
            const describeQuery = `DESCRIBE <${uri}>`;
            
            if (queryTextarea) {
                queryTextarea.value = describeQuery;
                queryTextarea.focus();
                
                // Auto-resize after setting the query
                queryTextarea.style.height = 'auto';
                queryTextarea.style.height = Math.max(queryTextarea.scrollHeight, 200) + 'px';
                
                // Scroll to the query form
                queryTextarea.scrollIntoView({ behavior: 'smooth', block: 'start' });
                
                // Auto-execute the DESCRIBE query
                const form = queryTextarea.closest('form');
                if (form) {
                    form.submit();
                }
            }
        }
    });

    // Copies an example query into the query box
    function useExampleQuery(query) {
        if (!queryTextarea) return;

        queryTextarea.value = query;
        queryTextarea.dispatchEvent(new Event('input')); // resizes the textarea
        queryTextarea.focus();
        queryTextarea.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }

    // Switching the example queries between the panels and the dropdown views, remembering the choice
    const exampleViewStorageKey = 'sparql-example-query-view';
    const exampleViewButtons = document.querySelectorAll('button[data-example-view]');
    const exampleViews = document.querySelectorAll('.example-queries-view');

    function showExampleView(view) {
        exampleViews.forEach(element => {
            element.style.display = element.dataset.exampleView === view ? '' : 'none';
        });
        exampleViewButtons.forEach(button => {
            const selected = button.dataset.exampleView === view;
            button.classList.toggle('active', selected);
            button.setAttribute('aria-pressed', selected);
        });
    }

    exampleViewButtons.forEach(button => {
        button.addEventListener('click', function() {
            showExampleView(this.dataset.exampleView);
            try {
                localStorage.setItem(exampleViewStorageKey, this.dataset.exampleView);
            } catch (e) {
                // the choice just isn't remembered
            }
        });
    });

    try {
        const savedView = localStorage.getItem(exampleViewStorageKey);
        if (savedView && document.querySelector(`.example-queries-view[data-example-view="${savedView}"]`)) {
            showExampleView(savedView);
        }
    } catch (e) {
        // the default view is shown
    }

    // Panels view: each example has a button to use it, and they can be filtered
    document.querySelectorAll('.use-query').forEach(button => {
        button.addEventListener('click', function() {
            useExampleQuery(this.dataset.query);
        });
    });

    const queryFilter = document.getElementById('query-filter');
    const queriesContainer = document.getElementById('example-queries-container');
    const noQueriesMessage = document.getElementById('no-queries-message');

    if (queryFilter && queriesContainer) {
        queryFilter.addEventListener('input', function() {
            const filterText = this.value.toLowerCase().trim();
            let visibleCount = 0;

            queriesContainer.querySelectorAll('.example-query').forEach(example => {
                const text = ['.query-title', '.example-query-description', '.query-code']
                    .map(selector => example.querySelector(selector)?.textContent || '')
                    .join(' ').toLowerCase();
                const matches = filterText === '' || text.includes(filterText);
                example.parentElement.style.display = matches ? '' : 'none';
                if (matches) visibleCount++;
            });

            if (noQueriesMessage) {
                noQueriesMessage.style.display = visibleCount === 0 && filterText !== '' ? 'block' : 'none';
            }
        });

        // Escape clears the filter
        queryFilter.addEventListener('keydown', function(e) {
            if (e.key === 'Escape') {
                this.value = '';
                this.dispatchEvent(new Event('input'));
            }
        });
    }

    // Dropdown view: selecting an example shows a preview, and the button copies it into the query
    const exampleSelect = document.getElementById('example-query-select');
    const examplePreview = document.getElementById('example-query-preview');
    const useExampleBtn = document.getElementById('use-example-query');

    if (exampleSelect && examplePreview && useExampleBtn) {
        exampleSelect.addEventListener('change', function() {
            const option = this.options[this.selectedIndex];
            if (!option.value) {
                examplePreview.style.display = 'none';
                return;
            }
            // textContent, so the query and description are shown as text rather than parsed as HTML
            examplePreview.querySelector('.example-query-description').textContent = option.dataset.description || '';
            examplePreview.querySelector('.query-code').textContent = option.dataset.query;
            examplePreview.style.display = '';
        });

        useExampleBtn.addEventListener('click', function() {
            const option = exampleSelect.options[exampleSelect.selectedIndex];
            if (option.value) useExampleQuery(option.dataset.query);
        });
    }
});