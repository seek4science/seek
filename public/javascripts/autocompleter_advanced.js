// Code made by RoRCraft limited, 2004-2008
// Taken from http://devblog.rorcraft.com/2008/8/13/the-facebook-autocomplete-address-to-field
// (relevant CSS file and pictures also obtained from the same website).


/* Improvements to the code made for SysMO:

- refactored code so it's not tailored specifically for email input anymore;
  (IDs of the recognised objects are submitted instead of "emails") 

Note: input that is validated - on successful validation it is turned into
"tokens"; only data from "tokens" is submitted afterwards.

- recognised user input is turned into "tokens" and IDs of the items which are
selected from the suggestion list are submitted in params[:ids];

- unrecognised input is dealt with separately; it first is validated according
to the selected validation type (the code now accepts a new parameter "validation_type");
(please see 'usage' below for details)

- bug-fix: "comma" after unsuccessfully validated unrecognised items was echoed
and prevented further suggestions; now it's not echoed anymore and further
suggestion show properly;

- implemented selection for "hint_field" and "id_field" - details in "usage" section;

- implemented JS function to fetch an array of selected "id_field" valued;

- implemented ability to prepopulate the text field with "tokens" on page load,
  array of item IDs to be prepopulated now can be (optionally can be empty if
  prepopulation is not required) submitted with the constructor call; 

*/


/* Usage of Autocompleter.LocalAdvanced
 * (HTML example of embedding Autocompleter.LocalAdvanced into a page can be found at the end of the file.) 
 *
 * Instances of this class are associated with a text field for data entry. These are then used to perform
 * lookup within arrays of items and populate auto-complete suggestion menus. Suggestions will be presented 
 * on two lines per item: containing the actual looked up values on the first line and some disambiguation
 * information on the second. Autocompleter can be configured to use desired attributes of items in the
 * submitted array to perform lookup and display hints.
 *
 * Selected suggestions will be turned into "tokens" in the text field - like Facebook does. Each "token" has
 * a corresponding hidden input that will submit a value (can be configured) when the form containing such
 * auto-complete field is submitted back to the server.
 *
 * "Tokens" can be prepopulated when the page is loading. Commas are used to delimit "tokens" when typing.
 *
 *
 * Syntax for the constructor:
 * new Autocompleter.LocalAdvanced(id_of_text_field, id_of_div_to_populate, item_array, item_ids_to_prepopulate, options), where parameters mean:
 * -- id_of_text_field - id of the monitored text field;
 * -- id_of_div_to_populate - id of the autocompletion menu;
 * -- item_array - JSON array of hashes containing values to lookup for the autocomplete menu; it should be in the following format:
 *                 [ ..., { key1: value1, key2: value2, ... }, ...]; each hash in this array should have several attributes for each item -
 *                 generally 3 attributes for every item are needed: "search_field" to look up on, "hint field" to display second line
 *                 in the suggestion and "id_field" to submit a value of selected "token" (see "options" below for the list of required keys);  
 *                 this array MUST be sorted by the "id_field" key;
 * -- item_ids_to_prepopulate - JSON array containing item IDs in "item_array" (this parameter can be passed in as empty):
 *                              these IDs should be of the same type as "id_field" contains,
 *                              (NB! these values are not the actual indices into "item_array", but rather IDs of the items stored in that array!);
 *                              this array MUST be sorted by IDs in ascending order;
 *                              
 *                              Note on operation: items on prepopulation will be searched by matching values in "item_ids_to_prepopulate"
 *                              array with "id_field" of values in "item_array"; prepopulated "tokens" will have values of "search_field" from items
 *                              in "item_array" - this is because that's the way the "tokens" would appear when typed-and-selected from suggestions. 
 *
 * -- options: a hash of attributes; all should be set if not specifically indicated otherwise:
 *    - frequency: decimal value, indicates how often to recalculate suggestions (e.g.: 0.1)
 *
 *    - updateElement: JavaScript function to call, when an element matches typed text (by default SHOULD be set to: addContactToList),
 *
 *    - search_field: key name for hashes within "item_array", within which the suggestion lookup is to be made (e.g.: "name"),
 *                    values found by access via this key MUST be of string type;
 *
 *    - hint_field: key name for hashes within "item_array" to get object hints that are displayed as
 *                  a second line in the suggestions menu for disambiguation (e.g.: "email"),
 *                  (OPTIONAL: this can be omitted, no additional info about every item will be displayed);
 *
 *    - id_field: key name for hashes within "item_array" to get UNIQUE identifiers for selected suggestions; 
 *                these MUST be set for all items in the "item_array"; "id_field" can be the same as "search_field" if
 *                values in "search_field" are unique (e.g.: "id" for any object, or "tag" for tags - if these can't be duplicated);
 *                these values will be submitted with the form containing the autocomplete field (or can be collected with JavaScript from
 *                ALL elements on the page which have their name set to "selected_ids[]").
 *
 *    -	validation_type: type of validation to perform on new input values that are not recognised by searching though
 *                       "item_array" data; successfully validated new entries will be submitted with the form
 *                       (or can be collected with JavaScript from ALL elements on the page which have their name set to "unrecognized_items[]");
 *                       validation is initiated when comma is pressed in the input text field; 
 *                       
 *                       so far the following types defined -
 *                       ** "any": any input which wasn't recognised is turned into "tokens" in the text
 *                          box and consequently submitted;
 *                       ** "only_suggested": any input which wasn't recognised (i.e. wasn't displayed in
 *                                            suggestions) is not allowed and will be rejected;
 *                       ** "email": new objects will have to comply with email validation rules to be
 *                                   turned into "tokens" (suggested items are also allowed);
 *                       - (OPTIONAL: this can be omitted, then "any" will be used by default);
*/



// Init - preload images
(new Image()).src='/images/autocompleter_tokens/token.gif';
(new Image()).src='/images/autocompleter_tokens/token_selected.gif';
(new Image()).src='/images/autocompleter_tokens/token_hover.gif';
(new Image()).src='/images/autocompleter_tokens/token_x.gif';


var VALIDATION_TYPE = "any";
var SEARCH_FIELD = null;
var HINT_FIELD = null;
var ID_FIELD = null;
var SUGGESTIONS_ARRAY = null;

validate_item = function(item) {
  // this method is only called for unrecognized items,
  // hence can return 'false' immediately if no unrecognized
  // items are allowed
  switch(VALIDATION_TYPE) {
    case "any":
      // no validation is required for such type
      return(true);
      break;
    case "only_suggested":
      return(false);
      break;
    case "email":
      var regexEmail = /^(("[\w-\s]+")|([\w-]+(?:\.[\w-]+)*)|("[\w-\s]+")([\w-]+(?:\.[\w-]+)*))(@((?:[\w-]+\.)*\w[\w-]{0,66})\.([a-z]{2,6}(?:\.[a-z]{2})?)$)|(@\[?((25[0-5]\.|2[0-4][0-9]\.|1[0-9]{2}\.|[0-9]{1,2}\.))((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[0-9]{1,2})\.){2}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[0-9]{1,2})\]?$)/i
      return regexEmail.test(item);
      break;
    
  }  
}

Autocompleter.LocalAdvanced = Class.create(Autocompleter.Base, {
    initialize: function(element, update, array, prepopulate_array, options) {
        this.baseInitialize(element, update, options);
        this.options.array = array;
        
        // this is set with an external parameter and defines the type of validation 
        // that the objects that are typed into the text box have to undergo
        VALIDATION_TYPE = options.validation_type;
        
        // the field by which the suggestion lookup is to be made; and one to be displayed in
        // the text box as a label of the "token"
        SEARCH_FIELD = options.search_field;
        
        // defines the field to fetch the values for the clarification
        // (i.e. 'search field' could be Name, but 'hint field' email to disambiguate findings)
        HINT_FIELD = options.hint_field;
        
        // the field to fetch the values that will be submitted as a result of selection of
        // suggested objects (e.g. ID of something or any other unique field within "item_array")
        ID_FIELD = options.id_field;
        
        // makes the supplied array of suggestions available everywhere
        SUGGESTIONS_ARRAY = array;
        
        this.wrapper = $(this.element.parentNode);

	    if (!this.element.hacks) {
	        this.element.should_use_borderless_hack = Prototype.Browser.WebKit;
	        this.element.should_use_shadow_hack = Prototype.Browser.IE || Prototype.Browser.Opera;
	        this.element.hacks = true;
	    }
		if (this.element.should_use_borderless_hack  || this.element.should_use_shadow_hack) { this.wrapper.addClassName('tokenizer_input_borderless'); }
		
		this.options.onShow = function(element,update) {
		 	Position.clone(element.parentNode.parentNode, update, {
		            setHeight: false, 
					setWidth: false,
		            offsetTop: element.parentNode.parentNode.offsetHeight
		     });		
			update.show(); 
			
		}  
		this.options.onHide = function(element, update){ update.hide() };
	    
    // PREPOPULATE THE TEXT FIELD WITH GIVEN SELECTION
    prepopulateTextField(prepopulate_array)
    },
getUpdatedChoices: function() {
        this.updateChoices(this.options.selector(this));

    },

onBlur: function($super, event) {
        $super();
        //move itself back to the end on blur
        if (this.wrapper.nextSiblings().length > 0) {
            this.wrapper.nextSiblings().last().insert({
                after: this.wrapper
            });

        }

    },
set_input_size: function(size) {
	size = size || 20;
	this.element.setStyle({width: size + "px"});	
},
onKeyPress: function(event) {
        //dynamically resize the input field
		var new_size = 20 + (this.element.value.length * 7);
        if (new_size <= 340) {
			this.set_input_size(new_size);
        } else {
			this.set_input_size(340);
        }
        //active is when there's suggestions found;
        /* 
           next section will get executed only when there were some suggestions, *but*
           the "comma" button wasn't pressed - comma will always denote a break in the
           current item and will make the code think that current item has finished
        */
        if (this.active && event.keyCode != 188)
        switch (event.keyCode) {
        case Event.KEY_TAB:
        case Event.KEY_RETURN:
            this.selectEntry();
            Event.stop(event);
            case Event.KEY_ESC:
            this.hide();
            this.active = false;
            Event.stop(event);
            return;
            case Event.KEY_LEFT:
        case Event.KEY_RIGHT:
            return;
            case Event.KEY_UP:
            this.markPrevious();
            this.render();
            Event.stop(event);
            return;
            case Event.KEY_DOWN:
            this.markNext();
            this.render();
            Event.stop(event);
            return;

        }
        else {
            if (event.keyCode == Event.KEY_TAB || event.keyCode == Event.KEY_RETURN || 
            (Prototype.Browser.WebKit > 0 && event.keyCode == 0) || event.keyCode == 44 /* , comma */ ||  event.keyCode == 188 ) {
                var unrecognized_item = this.element.value.strip().sub(',', '')
                //recognise the item format
                if (validate_item(unrecognized_item)) {
                    addUnrecognizedItemToList(unrecognized_item);
                    Event.stop(event);
                } 
                this.element.value = "";
				        this.set_input_size();
				        
				        // this will prevent from echoing the comma in the text box, if the item wasn't recognized and wasn't allowed to be turned into a token
				        Event.stop(event);
                return false;

            }
            switch (event.keyCode) {
                //jump left to token
                case Event.KEY_LEFT:
            case Event.KEY_BACKSPACE:
                if (this.element.value == "" && typeof this.wrapper.previous().token != "undefined") {
                    this.wrapper.previous().token.select();

                }
                return;
                //jump right to token
                case Event.KEY_RIGHT:
                if (this.element.value == "" && this.wrapper.next() && typeof this.wrapper.next().token != "undefined") {
                    this.wrapper.next().token.select();

                }

            }

        }

        this.changed = true;
        this.hasFocus = true;

        if (this.observer) clearTimeout(this.observer);
        this.observer = 
        setTimeout(this.onObserverEvent.bind(this), this.options.frequency * 1000);

    },

setOptions: function(options) {
        this.options = Object.extend({
            choices: 10,
            partialSearch: true,
            partialChars: 2,
            ignoreCase: true,
            fullSearch: false,
            selector: function(instance) {
                var ret = [];
                // Beginning matches
                var partial = [];
                // Inside matches
                var entry = instance.getToken();
                var count = 0;

                for (var i = 0; i < instance.options.array.length && 
                ret.length < instance.options.choices; i++) {

                    var elem = instance.options.array[i];
                    var elem_name = elem[instance.options.search_field];
                    var foundPos = instance.options.ignoreCase ? 
                    elem_name.toLowerCase().indexOf(entry.toLowerCase()) : 
                    elem_name.indexOf(entry);

                    while (foundPos != -1) {

                        if (foundPos == 0 && elem_name.length != entry.length) {
                            var value = "<strong>" + elem_name.substr(0, entry.length) + "</strong>" + elem_name.substr(entry.length);
                            ret.push(
                            "<li value='" + i + "'>" + "<div>" + value + "</div>"
                            + (HINT_FIELD ? ("<div>" + elem[HINT_FIELD] + "</div>") : "") + "</li>"
                            );
                            break;

                        } else if (entry.length >= instance.options.partialChars && instance.options.partialSearch && foundPos != -1) {
                            if (instance.options.fullSearch || /\s/.test(elem_name.substr(foundPos - 1, 1))) {
                                var value = elem_name.substr(0, foundPos) + "<strong>" + 
                                elem_name.substr(foundPos, entry.length) + "</strong>" + elem_name.substr(
                                foundPos + entry.length)

                                partial.push(
                                "<li value='" + i + "'>" + "<div>" + value + "</div>"
                                + (HINT_FIELD ? ("<div>" + elem[HINT_FIELD] + "</div>") : "") + "</li>"
                                );
                                break;

                            }

                        }
                        foundPos = instance.options.ignoreCase ? 
                        elem_name.toLowerCase().indexOf(entry.toLowerCase(), foundPos + 1) : 
                        elem_name.indexOf(entry, foundPos + 1);


                    }

                }
                if (partial.length)
                ret = ret.concat(partial.slice(0, instance.options.choices - ret.length));
                return "<ul>" + ret.join('') + "</ul>";

            }

        },
        options || {});

    }

});
HiddenInput = Class.create({
    initialize: function(element, auto_complete) {
        this.element = $(element);
        this.auto_complete = auto_complete;
        this.token;
        Event.observe(this.element, 'keydown', this.onKeyPress.bindAsEventListener(this));

    },
    onKeyPress: function(event) {
        if (this.token.selected) {
            switch (event.keyCode) {
                case Event.KEY_LEFT:
                this.token.element.insert({
                    before:
                    this.auto_complete.wrapper
                })
                this.token.deselect();
                this.auto_complete.element.focus();
                return false;
                case Event.KEY_RIGHT:
                this.token.element.insert({
                    after:
                    this.auto_complete.wrapper
                })
                this.token.deselect();
                this.auto_complete.element.focus();
                return false;
                case Event.KEY_BACKSPACE:
            case Event.KEY_DELETE:
                this.token.element.remove();
                this.auto_complete.element.focus();
                return false;

            }

        }

    }


})
 Token = Class.create({
    initialize: function(element, hidden_input) {
        this.element = $(element);
        this.hidden_input = hidden_input;
        this.element.token = this;
        this.selected = false;
        Event.observe(document, 'click', this.onclick.bindAsEventListener(this));

    },
    select: function() {
        this.hidden_input.token = this;
        this.hidden_input.element.activate();
        this.selected = true;
        this.element.addClassName('token_selected');

    },
    deselect: function() {
        this.hidden_input.token = undefined;
        this.selected = false;
        this.element.removeClassName('token_selected')

    },
    onclick: function(event) {
        if (this.detect(event) && !this.selected) {
            this.select();

        } else {
            this.deselect();

        }

    },
    detect: function(e) {
        //find the event object
        var eventTarget = e.target ? e.target: e.srcElement;
        var token = eventTarget.token;
        var candidate = eventTarget;
        while (token == null && candidate.parentNode) {
            candidate = candidate.parentNode;
            token = candidate.token;

        }
        return token != null && token.element == this.element;

    }

});


addContactToList = function(item) {
    $('autocomplete_input').value = "";
    var token = Builder.node('a', {
        "class": 'token',
        href: "#",
        tabindex: "-1"
    },
    Builder.node('span', 
    Builder.node('span', 
    Builder.node('span', 
    Builder.node('span', {},
    [Builder.node('input', { type: "hidden", name: "selected_ids[]",
        // NEXT LINE REPLACED TO SUBMIT REQUIRED FIELD OF THE SELECTED OBJECTS, INSTEAD OF BEING FIXED TO EMAILS
        //value: item.lastChild.innerHTML
        value: contacts[Element.readAttribute(item,'value')][ID_FIELD]
    }),
    // NEXT LINE REPLACED TO SET TOKEN LABEL TO 'SEARCH_FIELD' CONTENTS INSTEAD OF 'name' AS HARD-CODED SELECTION
	  contacts[Element.readAttribute(item,'value')][SEARCH_FIELD],
        Builder.node('span',{"class":'x',onmouseout:"this.className='x'",onmouseover:"this.className='x_hover'",
        onclick:"this.parentNode.parentNode.parentNode.parentNode.parentNode.remove(true); return false;"}," ")
        ]
    )
    )
    )   
    )
	);  
	// NEXT LINE IS COMMENTED OUT, BECAUSE IT WAS MAKING ERRORS IN InternetExplorer 
	//$(token).down(4).next().innerHTML = "&nbsp;";
 	new Token(token,hidden_input);
   $('autocomplete_display').insert({before:token});
}


addUnrecognizedItemToList = function(item) {
/*   $('autocomplete_input').value = "";*/
   var token = Builder.node('a',{"class":'token',href:"#",tabindex:"-1"},
       Builder.node('span',
       Builder.node('span',
       Builder.node('span',
       Builder.node('span',{},[
           Builder.node('input',{type:"hidden",name:"unrecognized_items[]",value: item} ) ,
           item,
           Builder.node('span',{"class":'x',onmouseout:"this.className='x'",onmouseover:"this.className='x_hover'",
           onclick:"this.parentNode.parentNode.parentNode.parentNode.parentNode.remove(true); return false;"}," ")
           ]
       )
       )
       )   
       )
   );  
  // NEXT LINE IS COMMENTED OUT, BECAUSE IT WAS MAKING ERRORS IN InternetExplorer
	//$(token).down(4).next().innerHTML = "&nbsp;";
   new Token(token,hidden_input);
   $('autocomplete_display').insert({before:token});
}


// *****************************************************

function getRecognizedSelectedIDs(){
  var x=document.getElementsByName("selected_ids[]");
  
  var res = new Array;
  for(var i = 0; i < x.length; i++)
    res[i] = x[i].value;
  
  return(res);
}


function itemIDsToJsonArrayIDs(item_id_array) {
  // array to store the "translated" IDs into the integer IDs of the SUGGESTIONS_ARRAY
  var suggestions_array_ids = new Array();
  var cnt = 0;
  
  var i = 0;
  while((i < SUGGESTIONS_ARRAY.length) && (cnt < item_id_array.length)) {
    if(SUGGESTIONS_ARRAY[i][ID_FIELD] == item_id_array[cnt]) {
      suggestions_array_ids[cnt] = i;
      cnt++;
    }
    else {
      i++;
    }
  }
  
  return(suggestions_array_ids);
}


function prepopulateTextField(item_id_array) {
  var suggestions_array_ids = itemIDsToJsonArrayIDs(item_id_array);
  
  var item = null;
  for(var i = 0; i < suggestions_array_ids.length; i++) {
    item = new Element('a', { 'value': suggestions_array_ids[i] });
    addContactToList(item);
  }
}



// ************************************************************************************************************************************

/* Example of simple HTML page using the Autocompleter Advanced: 

<div id="facebook" class="clearfix">
   <label for="autocomplete_display">To:</label>
  
	<div>
    <div tabindex="-1" id="ids" class="clearfix tokenizer" onclick="$('autocomplete_input').focus()">
      <span class="tokenizer_stretcher">^_^</span><span class="tab_stop"><input type="text" id="hidden_input" tabindex="-1"></span>
      
      <div id="autocomplete_display" class="tokenizer_input">
         <input type="text" size="1" tabindex="" id="autocomplete_input" />
      </div>                                                                          
    </div>
    <div id="autocomplete_populate" class="clearfix autocomplete typeahead_list" style="width: 358px; height: auto; overflow-y: hidden;display:none">
       <div class="typeahead_message">Type the name of a friend, friend list, or email address</div>                       
    </div>  
  </div>
</div>
    
<script type="text/javascript">
  var contacts = [ {'name': 'John Smith', 'email': 'john@smith.com', 'id': '1' },
	                 {'name': 'Joe Bloggs', 'email': 'joe@bloggs.org', 'id': '78' },
									 {'name': 'Mike Peters', 'email': 'mike@peters.co.uk', 'id': '131' }  ];
	var prepopulate_with = [1,131];

  var typeahead = new Autocompleter.LocalAdvanced('autocomplete_input', 'autocomplete_populate', contacts, prepopulate_with, {                                                  
      frequency: 0.1,
      updateElement: addContactToList,
      search_field: "name",
			hint_field: "email",
			id_field: "id",
			validation_type: "only_suggested"
  });
  var hidden_input = new HiddenInput('hidden_input',typeahead);
</script>

<br/>
<a href="" onclick="alert(getRecognizedSelectedIDs());return(false);">Show all 'id_field' values from selected tokens</a>
    
*/

