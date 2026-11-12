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

    // Example query dropdown: selecting an example shows a preview, and the button copies it into the query
    const exampleSelect = document.getElementById('example-query-select');
    const examplePreview = document.getElementById('example-query-preview');
    const useExampleBtn = document.getElementById('use-example-query');

    if (exampleSelect && examplePreview && useExampleBtn && queryTextarea) {
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
            if (!option.value) return;

            queryTextarea.value = option.dataset.query;
            queryTextarea.dispatchEvent(new Event('input')); // resizes the textarea
            queryTextarea.focus();
            queryTextarea.scrollIntoView({ behavior: 'smooth', block: 'start' });
        });
    }
});