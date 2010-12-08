
function showCode() {
   window.open(window.parent.mainFrame.document.URL + ".txt");
}

function URLescape(str) {
    var result = "";
    for (var i = 0; i < str.length; i++) {
        if (str.charAt(i) == "+") 
            result += "%2B"; 
        else 
            result += escape(str.charAt(i)); 
    }
    return result; 
}

function keyPress(event) {
	if (window.event) 
		keycode = window.event.keyCode;
	else if (event) 
		keycode = event.which;
	else 
		return true;
	
	//alert( keycode);
	
	if ( keycode != 13)
		return true;

	//alert( "foo");
	loadImage( );
}

function displayNormal() {
	var xmlHttp;
	try {  // Firefox, Opera 8.0+, Safari  
		xmlHttp = new XMLHttpRequest(); 
		if (xmlHttp.overrideMimeType) {
			xmlHttp.overrideMimeType('text/xml');
		}
	}
	catch (e) {  
	// Internet Explorer  
		try {    
			xmlHttp = new ActiveXObject("Msxml2.XMLHTTP"); 
		}
  		catch (e) {    
  			try {      
  				xmlHttp=new ActiveXObject("Microsoft.XMLHTTP");      
  			}
    		catch (e) {      
    			alert("Your browser does not support AJAX!");      
    			return false;      
    		}    
    	}  
    } 
    xmlHttp.onreadystatechange = function() {
		if(xmlHttp.readyState == 4) {
  			var xmlData = xmlHttp.responseXML;
  			var imgNode = xmlData.getElementsByTagName('img')[0];
  			var srcAttr = imgNode.attributes.getNamedItem("src");
  			var srcTxt = srcAttr.nodeValue;
  			var elem = document.getElementById("image");
  			elem.src = srcTxt;
   		}
	} 
	var mean = document.getElementById("mean").value;
	var sd = document.getElementById("sd").value;
	
	var low;
	var high;
	var above = document.getElementById("above").checked;
	var below = document.getElementById("below").checked;
	var between = document.getElementById("between").checked;
	var outside = document.getElementById("outside").checked;
	var outsideVal = "False";
	if ( above) {
		low = document.getElementById("abovevalue").value;
		high = "100000000";
	}
	else if ( below) {
		low = "-100000000";
		high = document.getElementById("belowvalue").value;
	}
	else if ( between) {
		low = document.getElementById("betweenvalue0").value;
		high = document.getElementById("betweenvalue1").value;
	}
	else if ( outside) {
		low = document.getElementById("outsidevalue0").value;
		high = document.getElementById("outsidevalue1").value;
		outsideVal = "True";
	}
	
	var url = "ReturnNormalImage.jsp";
	url=url+"?mean=" + mean + "&sd=" + sd + "&low=" + low + "&high=" + high + "&outside=" + outsideVal;
	xmlHttp.open("POST", url, true);
  	xmlHttp.send(null);
}
