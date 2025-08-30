document.addEventListener('DOMContentLoaded', function() {
    // Get DOM elements
    const clearBtn = document.getElementById('clear-query');
    const queryTextarea = document.getElementById('sparql_query');

    if (clearBtn && queryTextarea) {
        clearBtn.addEventListener('click', function() {
            queryTextarea.value = '';
            queryTextarea.focus();
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
});