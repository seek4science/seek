/* Based on source code from the Blog post by Mike Thomas at: http://atomicrobotdesign.com/blog/web-development/controlling-html-using-the-jquery-ui-slider-and-links/ */

jQuery(document).ready(function($j) {
    $j(function() {

        var imgarray = [];

        $j("#zoom img").each(function () {
            var img = '#' + $j(this).attr('id');
            imgarray.push(img);

        });

        // same order as scales_arr
        imgarray.reverse();

        var curImage = imgarray[0];
        var previousValue;
        var val=0;
        var scale_id;

        //slider mit 5 stufen, regler ist standardm��ig ganz oben
        //the jQuery slider has a build in event that fires every time the handle is moved on the slider called slide.
        //What we have set up here is that every time the slider handle is moved, we get the value and then run a function called valCheck.
        $j("#slider").slider({
            orientation: "vertical",
            min: 0,
            max: (scales_arr.length - 1),
            value: current_scale,
            animate:true,
            slide: function (event, ui) {
                previousValue = val;
                val = ui.value;
                scale_id = "#" + scales_arr[val];
                $j(scale_id).click();
            },
        });



        //valCheck() just checks the variable val and then runs a function called imageSwap, passing in the current image and the image we want to display,
        //then we change the current image to the new image.
        function valCheck() {
            if (val > previousValue) {
                imageSwapZoomOut(curImage, imgarray[val]);
                curImage = imgarray[val];
            }
            else {
                imageSwapZoomIn(curImage, imgarray[val]);
                curImage = imgarray[val];
            }
            previousValue=val;
        }

        //ANIMATION if images are changing!!
        //we�re just passing in the current image and the new image, fading out the current one and then fading in the new image
        function imageSwapZoomIn(curImage, newImage) {
            $j(curImage).css({'opacity':'1'});
            $j(newImage).css({'opacity':'0'});
            $j(newImage).css({'height':'25%', 'marginLeft':'200px', 'marginTop':'105px'});
            $j(curImage).css({'display':'inline'});
            $j(newImage).css({'display':'inline'});
            $j(curImage).animate({
                height: "250%",
                marginLeft: "-120px",
                marginTop: "-222px",
                opacity:'0'
            }, {
                duration: 2000,
                queue: false,
                complete: function() {
                }
            });
            $j(newImage).animate({
                height: "100%",
                marginLeft: "0px",
                marginTop: "0px",
                opacity:'1'
            }, {
                duration: 2000,
                queue: false,
                complete: function() {
                }
            });


        }

        function imageSwapZoomOut(curImage, newImage) {
            $j(curImage).css({'opacity':'1'});
            $j(newImage).css({'opacity':'0'});
            $j(newImage).css({'height':'250%', 'marginLeft':'-120px', 'marginTop':'-222px'});
            $j(curImage).css({'display':'inline'});
            $j(newImage).css({'display':'inline'});
            $j(curImage).animate({
                height: "25%",
                marginLeft: "200px",
                marginTop: "105px",
                opacity:'0'
            }, {
                duration: 2000,
                queue: false,
                complete: function() {
                }
            });
            $j(newImage).animate({
                height: "100%",
                marginLeft: "0px",
                marginTop: "0px",
                opacity:'1'
            }, {
                duration: 2000,
                queue: false,
                complete: function() {
                }
            });
        }

        //We�re just setting val to be the same as num and then running valCheck when the user clicks one of the links, otherwise, the images would only swap when the user slides the handle back and forth. Now the image swap will work if the user either clicks the links or moves the slider.
        function moveSlider(e, num) {
            e.preventDefault();
            $j('#slider').slider(
                'value',
                [num]
            );
            val = num;

            valCheck();
        }

        scales_arr.forEach(function( scale ){
            $j('#' + scale).click(function(e) {
                moveSlider(e, scales_arr.indexOf(scale));
            });
        });

        //initial status
        previousValue = $j('#slider').slider(
            'value'
        );
        val = current_scale;
        scale_id = "#" + scales_arr[val];
        $j(scale_id).click();

    });
});

function load_tabs() {
    var tabberOptions = {'onLoad':function() {

    }};
    tabberAutomatic(tabberOptions);
}