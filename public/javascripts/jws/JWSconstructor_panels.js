// not animated collapse/expand
function togglePannelStatus(content)
{
    var expand = (content.style.display=="none");
    content.style.display = (expand ? "block" : "none");
    toggleChevronIcon(content);
}

function select_function(argument)
{
	var modelSelected = argument;
		alert(modelSelected);
}

function toggleContent() {
  // Get the DOM reference
  var contentId = document.getElementById("name_panel");
  var contentId2 = document.getElementById("reactions_panel");
  var contentId3 = document.getElementById("equations_panel");
  var contentId4 = document.getElementById("assignments_panel");
  var contentId5 = document.getElementById("initial_panel");
  var contentId6 = document.getElementById("parameters_panel");
  var contentId7 = document.getElementById("functions_panel");
  var contentId8 = document.getElementById("events_panel");
  var contentId9 = document.getElementById("annotated_reactions_panel");
  var contentId10 = document.getElementById("annotated_species_panel");
  // Toggle 
  if (contentId.style.display == 'block') {contentId.style.display = 'none';contentId2.style.display='none'; contentId3.style.display='none';contentId4.style.display='none'; contentId5.style.display='none'; contentId6.style.display='none'; contentId7.style.display='none'; contentId8.style.display='none'; contentId9.style.display='none'; contentId10.style.display='none'}
  else { contentId.style.display = 'block';contentId2.style.display='block'; contentId3.style.display='block';contentId4.style.display='block'; contentId5.style.display='block'; contentId6.style.display='block'; contentId7.style.display='block'; contentId8.style.display='block'; contentId9.style.display='block'; contentId10.style.display='block'}
}

// current animated collapsible panel content
var currentContent = null;

function togglePannelAnimatedStatus(content, interval, step)
{
    // wait for another animated expand/collapse action to end
    if (currentContent==null)
    {
        currentContent = content;
        var expand = (content.style.display=="none");
        if (expand)
            content.style.display = "block";
        var max_height = content.offsetHeight;

        var step_height = step + (expand ? 0 : -max_height);
        toggleChevronIcon(content);
                
        // schedule first animated collapse/expand event
        content.style.height = Math.abs(step_height) + "px";
        setTimeout("togglePannelAnimatingStatus(" + interval + "," + step
            + "," + max_height + "," + step_height + ")", interval);
    }
}

function togglePannelAnimatingStatus(interval, step, max_height, step_height)
{
    var step_height_abs = Math.abs(step_height);

    // schedule next animated collapse/expand event
    if (step_height_abs>=step && step_height_abs<=(max_height-step))
    {
        step_height += step;
        currentContent.style.height = Math.abs(step_height) + "px";
        setTimeout("togglePannelAnimatingStatus(" + interval + "," + step
            + "," + max_height + "," + step_height + ")", interval);
    }
    // animated expand/collapse done
    else
    {
        if (step_height_abs<step)
            currentContent.style.display = "none";
        currentContent.style.height = "";
        currentContent = null;
    }
}

// change chevron icon into either collapse or expand
function toggleChevronIcon(content)
{
    var chevron = content.parentNode.firstChild.childNodes[1].childNodes[0];
    var expand = (chevron.src.indexOf("expand.gif")>0);
    chevron.src = chevron.src
        .split(expand ? "expand.gif" : "collapse.gif")
        .join(expand ? "collapse.gif" : "expand.gif");
}

function createCookie(name,days) {
	if (days) {
		var date = new Date();
		date.setTime(date.getTime()+(days*86400000));
		var expires = "; expires="+date.toGMTString();
//		var value = document.getElementById("name_panel").style.display;
		var value = document.getElementById(name).style.display;
        if (value == null || value.blank()) {
            value = "block"
        }
	}
	else var expires = "";
	document.cookie = name+"="+value+expires+"; path=/";
}

function createCookie2(name,days,nameString) {
	if (days) {
		var date = new Date();
		date.setTime(date.getTime()+(days*86400000));
		var expires = "; expires="+date.toGMTString();
//		var value = document.getElementById("name_panel").style.display;
		var value = new Array(name.GetCurrentWidth(),name.GetCurrentHeight());	
//		var value = name.GetCurrentWidth();			
	}
	else var expires = "";
	document.cookie = nameString+"="+value+expires+"; path=/";
}	

function createCookie3(name,days,nameString) {
	if (days) {
		var date = new Date();
		date.setTime(date.getTime()+(days*86400000));
		var expires = "; expires="+date.toGMTString();
//		var value = document.getElementById("name_panel").style.display;
		var value = name.value;	
	}
	else var expires = "";
	document.cookie = nameString+"="+value+expires+"; path=/";
}

function createCookie4(name,days,nameString) {
	if (days) {
		var date = new Date();
		date.setTime(date.getTime()+(days*86400000));
		var expires = "; expires="+date.toGMTString();
//		var value = document.getElementById("name_panel").style.display;
		var value = name.y;	
	}
	else var expires = "";
	document.cookie = nameString+"="+value+expires+"; path=/";
}

function createCookie5(name,name2,days,nameString) {
	if (days) {
		var date = new Date();
		date.setTime(date.getTime()+(days*86400000));
		var expires = "; expires="+date.toGMTString();
//		var value = document.getElementById("name_panel").style.display;
		if (readCookie('rc')=='undefined' || readCookie('rc')==null) {var value = new Array(name2.GetCurrentWidth(),name2.GetCurrentHeight());} else {var value = new Array(rc.GetCurrentWidth(),rc.GetCurrentHeight());}; 
//		var value = new Array(name.GetCurrentWidth(),name.GetCurrentHeight());
	}
	else var expires = "";
	if(document.form.plotGraphPanel.value=='on') {document.cookie = nameString+"="+value+expires+"; path=/";
}
}

function createCookie6(name,name2,days,nameString) {
	if (days) {
		var date = new Date();
		date.setTime(date.getTime()+(days*86400000));
		var expires = "; expires="+date.toGMTString();
//		var value = document.getElementById("name_panel").style.display;
		if (readCookie('rc2')=='undefined' || readCookie('rc2')==null) {var value = new Array(name2.GetCurrentWidth(),name2.GetCurrentHeight());} else {var value = new Array(rc2.GetCurrentWidth(),rc2.GetCurrentHeight());}; 
//		var value = new Array(name.GetCurrentWidth(),name.GetCurrentHeight());
	}
	else var expires = "";
	if(document.form.plotKineticsPanel.value=='on') {
	document.cookie = nameString+"="+value+expires+"; path=/";
}
}

function readCookie(name) {
	var nameEQ = name + "=";
	var ca = document.cookie.split(';');
	for(var i=0;i < ca.length;i++) {
		var c = ca[i];
		while (c.charAt(0)==' ') c = c.substring(1,c.length);
		if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
	}
	return null;
}

function eraseCookie(name) {
	createCookie(name,"",-1);
}

function setTheDivStyle() {
if(!readCookie('name_panel')) {
// if cookie not found display the div and create the cookie
//document.getElementById("name_panel").style.display="block";
//createCookie('name_panel', 1);  // 1 day = 24 hours persistence
}
else {
// if cookie found hide the div
//alert('the cookie lives ' + readCookie('name_panel'))
document.getElementById("name_panel").style.display=readCookie('name_panel');
//document.getElementById("name_top").style.width=readCookie('name_top');
document.getElementById("reactions_panel").style.display=readCookie('reactions_panel');
document.getElementById("equations_panel").style.display=readCookie('equations_panel');
document.getElementById("assignments_panel").style.display=readCookie('assignments_panel');
document.getElementById("initial_panel").style.display=readCookie('initial_panel');
document.getElementById("parameters_panel").style.display=readCookie('parameters_panel');
document.getElementById("functions_panel").style.display=readCookie('functions_panel');
document.getElementById("events_panel").style.display=readCookie('events_panel');
document.getElementById("annotated_reaction_panel").style.display=readCookie('annotated_reaction_panel');
document.getElementById("annotated_species_panel").style.display=readCookie('annotated_species_panel');
rtmodelname.SetCurrentWidth(cookieToArray('rtmodelname')[0]);
rtmodelname.SetCurrentHeight(cookieToArray('rtmodelname')[1]);
rtreaction.SetCurrentWidth(cookieToArray('rtreaction')[0]);
rtreaction.SetCurrentHeight(cookieToArray('rtreaction')[1]);
rtkinetics.SetCurrentWidth(cookieToArray('rtkinetics')[0]);
rtkinetics.SetCurrentHeight(cookieToArray('rtkinetics')[1]);
rtassignmentRules.SetCurrentWidth(cookieToArray('rtassignmentRules')[0]);
rtassignmentRules.SetCurrentHeight(cookieToArray('rtassignmentRules')[1]);
rtinitVal.SetCurrentWidth(cookieToArray('rtinitVal')[0]);
rtinitVal.SetCurrentHeight(cookieToArray('rtinitVal')[1]);
rtparameterset.SetCurrentWidth(cookieToArray('rtparameterset')[0]);
rtparameterset.SetCurrentHeight(cookieToArray('rtparameterset')[1]);
rtfunctions.SetCurrentWidth(cookieToArray('rtfunctions')[0]);
rtfunctions.SetCurrentHeight(cookieToArray('rtfunctions')[1]);
rtevents.SetCurrentWidth(cookieToArray('rtevents')[0]);
rtevents.SetCurrentHeight(cookieToArray('rtevents')[1]);

rtAnnotatedReactions.SetCurrentWidth(cookieToArray('annotatedReactions')[0]);
rtAnnotatedReactions.SetCurrentHeight(cookieToArray('annotatedReactions')[1]);

rtAnnotatedSpecies.SetCurrentWidth(cookieToArray('annotatedSpecies')[0]);
rtAnnotatedSpecies.SetCurrentHeight(cookieToArray('annotatedSpecies')[1]);

document.form.plotGraphPanel.value=readCookie('plotGraphPanel');
document.form.plotKineticsPanel.value=readCookie('plotKineticsPanel');
if(document.form.plotGraphPanel.checked==true) {
	rc.SetCurrentWidth2(cookieToArray('rc')[0]);
	rc.SetCurrentHeight(cookieToArray('rc')[1]);
	};
if(document.form.plotKineticsPanel.checked==true) {rc2.SetCurrentWidth2(cookieToArray('rc2')[0]);rc2.SetCurrentHeight(cookieToArray('rc2')[1]);};
//alert(readCookie('plotGraphPanel'))
//self.scrollTo(150,150);
//alert(getScrollPos().y);
self.scrollTo(0,readCookie('scrollPos'));
//alert(readCookie('rc'));
//alert(cookieToArray('rc'))
}
}

function getScrollPos(){
	if (window.pageYOffset){
		return {y:window.pageYOffset, x:window.pageXOffset};
	}
	if(document.documentElement && document.documentElement.scrollTop){
		return {y:document.documentElement.scrollTop, x:document.documentElement.scrollLeft};
	}
	if(document.body){
		return {y:document.body.scrollTop, x:document.body.scrollLeft};
	}
	return {x:0, y:0};
}
function cookieToArray(cookiename){
	var cookieContents = readCookie(cookiename);
	var contentsArray = cookieContents.split(',');
	return contentsArray;
}

