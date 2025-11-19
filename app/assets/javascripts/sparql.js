document.addEventListener('DOMContentLoaded', function() {
    // Get DOM elements
    const clearQueryBtn = document.getElementById('clear-query');
    const clearResultsBtn = document.getElementById('clear-results');
    const queryTextarea = document.getElementById('sparql_query');

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

    // allow tabs, instead of jumping to next element
    if (queryTextarea) {
        queryTextarea.addEventListener('keydown', function(e) {
            if (e.key == 'Tab') {
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


    // Use example query buttons
    const useQueryButtons = document.querySelectorAll('.use-query');
    useQueryButtons.forEach(button => {
        button.addEventListener('click', function() {
            const queryText = this.dataset.query;
            if (queryTextarea) {
                queryTextarea.value = queryText;
                queryTextarea.focus();

                // Scroll to the query form
                queryTextarea.scrollIntoView({ behavior: 'smooth', block: 'start' });
            }
        });
    });

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

    // Handle example query dropdown
    const exampleQuerySelect = document.getElementById('example-queries');
    
    if (exampleQuerySelect && queryTextarea) {
        exampleQuerySelect.addEventListener('change', function() {
            const selectedOption = this.options[this.selectedIndex];
            
            if (selectedOption.value) {
                const rawQuery = selectedOption.dataset.query;
                
                // Decode HTML entities
                const tempDiv = document.createElement('div');
                tempDiv.innerHTML = rawQuery;
                const query = tempDiv.textContent || tempDiv.innerText || '';
                
                // Set the decoded query in the textarea
                queryTextarea.value = query;
                queryTextarea.focus();
                
                // Auto-resize after setting the query
                queryTextarea.style.height = 'auto';
                queryTextarea.style.height = Math.max(queryTextarea.scrollHeight, 200) + 'px';
                
                // Reset dropdown to default
                this.selectedIndex = 0;
                
                // Scroll to the query form
                queryTextarea.scrollIntoView({ behavior: 'smooth', block: 'start' });
            }
        });
    }

    // Example query filter functionality
    const queryFilter = document.getElementById('query-filter');
    const queriesContainer = document.getElementById('example-queries-container');
    const noQueriesMessage = document.getElementById('no-queries-message');
    
    if (queryFilter && queriesContainer) {
        queryFilter.addEventListener('input', function() {
            const filterText = this.value.toLowerCase().trim();
            const exampleQueries = queriesContainer.querySelectorAll('.example-query');
            let visibleCount = 0;
            
            exampleQueries.forEach(function(query) {
                const title = query.querySelector('.query-title strong');
                const description = query.querySelector('.text-muted');
                const queryCode = query.querySelector('.query-code');
                
                const titleText = title ? title.textContent.toLowerCase() : '';
                const descriptionText = description ? description.textContent.toLowerCase() : '';
                const codeText = queryCode ? queryCode.textContent.toLowerCase() : '';
                
                const matchesFilter = filterText === '' || 
                    titleText.includes(filterText) || 
                    descriptionText.includes(filterText) ||
                    codeText.includes(filterText);
                
                if (matchesFilter) {
                    query.parentElement.style.display = '';
                    visibleCount++;
                } else {
                    query.parentElement.style.display = 'none';
                }
            });
            
            // Show/hide "no results" message
            if (noQueriesMessage) {
                if (visibleCount === 0 && filterText !== '') {
                    noQueriesMessage.style.display = 'block';
                } else {
                    noQueriesMessage.style.display = 'none';
                }
            }
        });
        
        // Clear filter when escape key is pressed
        queryFilter.addEventListener('keydown', function(e) {
            if (e.key === 'Escape') {
                this.value = '';
                this.dispatchEvent(new Event('input'));
            }
        });
    }
});