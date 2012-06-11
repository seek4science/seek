function viewPDFContent(url) {
    PDFJS.disableWorker = true;
    'use strict';

    pdfDoc = null;
    pageNum = 1;
    scale = 1;
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

}

function hidePDFContent(){
    document.getElementById('pdf_content_display').style['display'] = 'none';
    document.getElementById('pdf-display-canvas').innerHTML="";
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
