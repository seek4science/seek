// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults


var tabber_ids = new Array();
var tabberOptions = {'onLoad':function() {
    displayTabs();
}};

function displayTabs() {

    for (var i = 0; i < tabber_ids.length; i++) {
        var tabber_id = tabber_ids[i];
        var spinner = $(tabber_id + "_spinner");
        if (spinner != null) {
          spinner.hide();
          Effect.Appear(tabber_id, {duration : 0.5}); 
        }
    }
}


function trimSpaces(str) {
    while ((str.length > 0) && (str.charAt(0) == ' '))
        str = str.substring(1);
    while ((str.length > 0) && (str.charAt(str.length - 1) == ' '))
        str = str.substring(0, str.length - 1);
    return str;
}

function addToolListTag(tag_id) {
    tools_autocompleter = autocompleters['tools_autocompleter']
    var index = tools_autocompleter.itemIDsToJsonArrayIDs([tag_id])[0];
    var item = new Element('a', {
        'value': index
    });
    tools_autocompleter.addContactToList(item);
}

function addExpertiseListTag(tag_id) {
    expertise_autocompleter = autocompleters['expertise_autocompleter']
    var index = expertise_autocompleter.itemIDsToJsonArrayIDs([tag_id])[0];
    var item = new Element('a', {
        'value': index
    });
    expertise_autocompleter.addContactToList(item);
}

function addOrganismListTag(tag_id) {

    organism_autocompleter = autocompleters['organism_autocompleter']
    var index = organism_autocompleter.itemIDsToJsonArrayIDs([tag_id])[0];
    var item = new Element('a', {
        'value': index
    });
    organism_autocompleter.addContactToList(item);
}


function checkNotInList(id, list) {
    rtn = true;

    for (var i = 0; i < list.length; i++)
        if (list[i][1] == id) {
            rtn = false;
            break;
        }

    return(rtn);
}

function clearList(name) {
    select = $(name)
    while (select.length > 0) {
        select.remove(select.options[0])
    }
}


//Add the last tag entered onto the list when the element becomes unfocused.
//Code taken from the onKeyPress method of autocompleter_advanced.js.
function addLastTag(autocompleter_id){
    var autocompleter = autocompleters[autocompleter_id];
    var unrecognized_item = autocompleter.element.value.strip().sub(',', '');
    if (unrecognized_item.length > 0 && autocompleter.validate_item(unrecognized_item)) {
      autocompleter.addUnrecognizedItemToList(unrecognized_item);
      autocompleter.element.value = "";        
      autocompleter.set_input_size();
    }
    return false;
  }
  
  
/*==================================================
  Cookie functions - courtesy of BioCatalogue
  ==================================================*/
function setCookie(name, value, expires, path, domain, secure) {
    document.cookie= name + "=" + escape(value) +
        ((expires) ? "; expires=" + expires.toGMTString() : "") +
        ((path) ? "; path=" + path : "") +
        ((domain) ? "; domain=" + domain : "") +
        ((secure) ? "; secure" : "");
}

function getCookie(name) {
    var dc = document.cookie;
    var prefix = name + "=";
    var begin = dc.indexOf("; " + prefix);
    if (begin == -1) {
        begin = dc.indexOf(prefix);
        if (begin != 0) return null;
    } else {
        begin += 2;
    }
    var end = document.cookie.indexOf(";", begin);
    if (end == -1) {
        end = dc.length;
    }
    return unescape(dc.substring(begin + prefix.length, end));
}
function deleteCookie(name, path, domain) {
    if (getCookie(name)) {
        document.cookie = name + "=" +
            ((path) ? "; path=" + path : "") +
            ((domain) ? "; domain=" + domain : "") +
            "; expires=Thu, 01-Jan-70 00:00:01 GMT";
    }
}

var fullResourceListItemExpandableText = new Array();
var truncResourceListItemExpandableText = new Array();

function expandResourceListItemExpandableText(objectId){
    link = $('expandableLink'+objectId)
    text = $('expandableText'+objectId)
    if (link.innerHTML == '(Expand)') { //EXPAND
      link.innerHTML = '(Collapse)';
      text.innerHTML = fullResourceListItemExpandableText[objectId];
    }
    else { //COLLAPSE
      link.innerHTML = '(Expand)';
      text.innerHTML = truncResourceListItemExpandableText[objectId];
    }
}

function toggleAuthorAvatarList(objectId){
    div = $('authorAvatarList'+objectId)
    link = $('authorAvatarListLink'+objectId)    
    if (div.style.display == "none") { //EXPAND
      div.style.display = "";
      link.innerHTML = '(Hide)';
    }
    else { //COLLAPSE
      div.style.display = "none";
      link.innerHTML = '(Show All)';
    }
}


//http://snipplr.com/view.php?codeview&id=1384
function insertAtCursor(myField, myValue) {
  myField = $(myField);

  textAreaScrollPosition = myField.scrollTop;

  //IE support
  if (document.selection) {
    myField.focus();
    sel = document.selection.createRange();
    sel.text = myValue;
  }
  //MOZILLA/NETSCAPE support
  else if (myField.selectionStart || myField.selectionStart == '0') {
    var startPos = myField.selectionStart;
    var endPos = myField.selectionEnd;
    myField.value = myField.value.substring(0, startPos)
                  + myValue 
                  + myField.value.substring(endPos, myField.value.length);
    myField.focus(); 
    myField.setSelectionRange(startPos + myValue.length, startPos + myValue.length);
  } else {
    myField.value += myValue;
  }
  
  myField.scrollTop = textAreaScrollPosition;
}


function toggle_collapsable_div(id) {
  var elem = $('collapsable_div_' + id);
  var toggle_img = $('collapsable_div_img_' + id);
  if (elem.style.display == 'none') {
    //Effect.BlindDown(('collapsable_div_' + id),{duration:0.2});
    toggle_img.src = "/images/folds/fold.png";
    elem.show();    
  }
  else {
    //Effect.BlindUp(('collapsable_div_' + id),{duration:0.2});
    toggle_img.src = "/images/folds/unfold.png";
    elem.hide();    
  }
}