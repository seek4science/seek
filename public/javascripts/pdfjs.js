function viewPDFContent(url) {
    if (isCanvasSupportBrowser){
        PDFJS.disableWorker = true;
        'use strict';

        pdfDoc = null;
        pageNum = 1;
        scale = 1.5;
        document.getElementById('pdf_content_display').style['display'] = 'block';
        canvas = document.getElementById('pdf-display-canvas');
        ctx = canvas.getContext('2d');

        //
        // Asynchronously download PDF as an ArrayBuffer
        //
        show_large_ajax_loader("ajax_loader");
        PDFJS.getDocument(url).then(function getPdfHelloWorld(_pdfDoc) {
            pdfDoc = _pdfDoc;
            renderPage(pageNum);
        });
    }else{
        alert('Your browser does not support html5 to view the pdf file inline, please upgrade the browser')
    }
}

function isCanvasSupportBrowser(){
    var test_canvas = document.createElement("canvas") //try and create sample canvas element
    var canvas_check=(test_canvas.getContext)? true : false //check if object supports getContext() method, a method of the canvas element
    return canvas_check;
}

function hidePDFContent(){
    document.getElementById('pdf_content_display').style['display'] = 'none';
}


//
// Get page info from document, resize canvas accordingly, and render page
//
function renderPage(num) {
    // Using promise to fetch the page
    pdfDoc.getPage(num).then(function (page) {
        var viewport = page.getViewport(scale);
        canvas.height = viewport.height;
        canvas.width = viewport.width;
        // Render PDF page into canvas context
        var renderContext = {
            canvasContext:ctx,
            viewport:viewport
        };
        page.render(renderContext);
    });
    // Update page counters
    document.getElementById('page_num').textContent = pageNum;
    document.getElementById('page_count').textContent = pdfDoc.numPages;
    $('ajax_loader').innerHTML = ""
}
//
// Go to previous page
//
function goPrevious() {
    if (pageNum <= 1)
        return;
    pageNum--;
    renderPage(pageNum);
}
//
// Go to next page
//
function goNext() {
    if (pageNum >= pdfDoc.numPages)
        return;
    pageNum++;
    renderPage(pageNum);
}
