// fold.js

function foldUpdate(el) {

  var title = getPaneTitleDiv(el);

  var img = "/images/folds/fold.png";

  if (getPaneBodyDiv(el).style.display == 'none')
    img = "/images/folds/unfold.png";

  var newTitle = document.createElement('DIV');

  newTitle.innerHTML = '<table class="foldTitle" onclick="javascript:foldToggle(this); return false;" ><tr><td class="foldText">' + el.titleHTML + '</td><td class="foldImage"><img src="' + img + '"></td></tr></table>';

  el.insertBefore(newTitle, title);
  el.removeChild(title);
}

function foldToggle(el) {

  function parent(el) {

    if (el.parentElement != undefined)
      return el.parentElement;

    return el.parentNode;
  }

  var pane = parent(parent(el));

  var style = getPaneBodyDiv(pane).style;

  if (style.display == 'none') {
    style.display = 'block';
  } else {
    style.display = 'none';
  }

  foldUpdate(pane);
}

function getTags(el, tag) {

  var result = new Array();

  for (var i = 0; i < el.childNodes.length; i++) {
    if (el.childNodes[i].tagName == tag) {
      result.push(el.childNodes[i]);
    }
  }
}

function getNthTag(el, tag, index) {

  var count = 0;

  for (var i = 0; i < el.childNodes.length; i++) {
    if (el.childNodes[i].tagName == tag) {
      if (count++ == index) {
        return el.childNodes[i];
      }
    }
  }
}

function getPaneTitleDiv(el) {
  return getNthTag(el, 'DIV', 0);
}

function getPaneBodyDiv(el) {
  return getNthTag(el, 'DIV', 1);
}

function initialiseFolds() {

  var divs = document.getElementsByTagName('DIV');

  for (var i = 0; i < divs.length; i++) {

    var div = divs[i];

    if (div.className == 'fold') {

      var paneCommands = document.createElement('SPAN');
      var title        = getPaneTitleDiv(div);

      title.insertBefore(paneCommands, title.firstChild);

      div.titleHTML = title.innerHTML;

      foldUpdate(div);
    }
  }
}

initialiseFolds();

