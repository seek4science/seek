// Code made by RoRCraft limited, 2004-2008
// Taken from http://devblog.rorcraft.com/2008/8/13/the-facebook-autocomplete-address-to-field
// (relevant CSS file and pictures also obtained from the same website).


/* Improvements to the code made for SysMO:

 - fully refactored code to allow several advanced autocompleters on the same page
 (the way this was implemented originally would not give any opportunity for this);

 - refactored code so it's not tailored specifically for email input anymore;
 (IDs of the recognised objects are submitted instead of "emails")

 Note: input that is validated - on successful validation it is turned into
 "tokens"; only data from "tokens" is submitted afterwards.

 - recognised user input is turned into "tokens" and IDs of the items which are
 selected from the suggestion list are submitted in params[:ids];

 - unrecognised input is dealt with separately; it first is validated according
 to the selected validation type (the code now accepts a new parameter "validation_type");
 (please see 'usage' below for details)

 - bug-fix: whole page was jumping upwards-downwards when arrow keys ('up' or 'down') were pressed
 on a page with advanced autocompleter on it;

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
 * new Autocompleter.LocalAdvanced(id_of_autocompleter, id_of_text_field, id_of_display_field, id_of_div_to_populate, item_array, item_ids_to_prepopulate, options), where parameters mean:
 * -- id_of_autocompleter - string that represents a unique identifier of this autocompleter;
 *                          this value is especially required when a page has several instances of an autocompleter -
 *                          these IDs are then used to allow JavaScript to perform actions with the relevant 'active' autocompleter only 
 * -- id_of_text_field - id of the monitored text field (see example at the end of the file);
 * -- id_of_display_field - id of the div that will hold and display curently selected "tokens" (see example at the end of the file);
 * -- id_of_div_to_populate - id of the autocompletion menu (see example at the end of the file);
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
 *                ALL elements on the page which have their name set to "<id_of_autocompleter>_selected_ids[]").
 *
 *    -	validation_type: type of validation to perform on new input values that are not recognised by searching though
 *                       "item_array" data; successfully validated new entries will be submitted with the form
 *                       (or can be collected with JavaScript from ALL elements on the page which have their name set to "<id_of_autocompleter>_unrecognized_items[]");
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
 *
 *
 * NOTE: the code will also *assume availability* of an associative array called "autocompleters", which has an
 *       element for every Advanced Autocompleter on the current page: these elements are accessed by <id_of_autocompleter>
 *       string value as a key and *MUST* contain a pointer to the instance of the autocompleter which has corresponding ID;
 *       (please see example at the end of the file).
 */



// Init - preload images
(new Image()).src = '../../images/autocompleter_tokens/token.gif';
(new Image()).src = '../../images/autocompleter_tokens/token_selected.gif';
(new Image()).src = '../../images/autocompleter_tokens/token_hover.gif';
(new Image()).src = '../../images/autocompleter_tokens/token_x.gif';


Autocompleter.LocalAdvanced = Class.create(Autocompleter.Base, {
    initialize: function(autocompleter_id, element, display_element, update, array, prepopulate_array, options) {
        this.autocompleter_id = autocompleter_id;

        this.baseInitialize(element, update, options);
        this.options.array = array;

        this.display_element = $(display_element);
        this.hidden_input = null;

        // this is set with an external parameter and defines the type of validation 
        // that the objects that are typed into the text box have to undergo
        this.VALIDATION_TYPE = "any";
        this.VALIDATION_TYPE = options.validation_type;

        // the field by which the suggestion lookup is to be made; and one to be displayed in
        // the text box as a label of the "token"
        this.SEARCH_FIELD = null;
        this.SEARCH_FIELD = options.search_field;

        // defines the field to fetch the values for the clarification
        // (i.e. 'search field' could be Name, but 'hint field' email to disambiguate findings)
        this.HINT_FIELD = null;
        this.HINT_FIELD = options.hint_field;

        // the field to fetch the values that will be submitted as a result of selection of
        // suggested objects (e.g. ID of something or any other unique field within "item_array")
        this.ID_FIELD = null;
        this.ID_FIELD = options.id_field;

        // makes the supplied array of suggestions available everywhere
        this.SUGGESTIONS_ARRAY = null;
        this.SUGGESTIONS_ARRAY = array;

        this.wrapper = $(this.element.parentNode);

        if (!this.element.hacks) {
            this.element.should_use_borderless_hack = Prototype.Browser.WebKit;
            this.element.should_use_shadow_hack = Prototype.Browser.IE || Prototype.Browser.Opera;
            this.element.hacks = true;
        }
        if (this.element.should_use_borderless_hack || this.element.should_use_shadow_hack) {
            this.wrapper.addClassName('tokenizer_input_borderless');
        }

        this.options.onShow = function(element, update) {
            Position.clone(element.parentNode.parentNode, update, {
                setHeight: false,
                setWidth: false,
                offsetTop: element.parentNode.parentNode.offsetHeight
            });
            update.show();

        }
        this.options.onHide = function(element, update) {
            update.hide()
        };


        // PREPOPULATE THE TEXT FIELD WITH GIVEN SELECTION
        // this will be done when associated hidden input is created as well -
        // this is because no "tokens" can be created until the associated
        // hidden input is initialized;
        // hence, just store the parameters for later use
        this.prepopulate_array = prepopulate_array;
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
    
    //Modified to remove last tag that was automatically added by the blurring of the input field
    //Modified further to only do the above for validation_type "any"
    onClick: function(event) {
      if(this.VALIDATION_TYPE == "any") {
        this.wrapper.previous().token.element.remove(true); //This removes the last element
      }
      var element = Event.findElement(event, 'LI');
      this.index = element.autocompleteIndex;
      this.selectEntry();
      this.hide();
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
                    this.markPreviousMod();
                    this.render();
                    Event.stop(event);
                    return;
                case Event.KEY_DOWN:
                    this.markNextMod();
                    this.render();
                    Event.stop(event);
                    return;

            }
        else {
            if (event.keyCode == Event.KEY_TAB || event.keyCode == Event.KEY_RETURN ||
                (Prototype.Browser.WebKit > 0 && event.keyCode == 0) || event.keyCode == 44 /* , comma */ || event.keyCode == 188) {
                var unrecognized_item = this.element.value.strip().sub(',', '')
                //recognise the item format
                if (this.validate_item(unrecognized_item)) {
                    this.addUnrecognizedItemToList(unrecognized_item);
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


    /*
     * The following block of code was taken from:
     * http://blog.gilluminate.com/2009/01/20/scriptaculous-autocomplete-page-jump-using-arrow-keys/
     *
     * This is meant to fix a bug in Scriptaculous which causes the whole page to jump when arrow keys
     * are used to make selections in the auto complete box.
     */

    // START OF BLOCK

    markPreviousMod: function() {
        if (this.index > 0) {
            this.index--;
        }
        else {
            this.index = this.entryCount - 1;
            this.update.scrollTop = this.update.scrollHeight;
        }
        selection = this.getEntry(this.index);
        selection_top = selection.offsetTop;
        if (selection_top < this.update.scrollTop) {
            this.update.scrollTop = this.update.scrollTop - selection.offsetHeight;
        }
    },

    markNextMod: function() {
        if (this.index < this.entryCount - 1) {
            this.index++;
        }
        else {
            this.index = 0;
            this.update.scrollTop = 0;
        }
        selection = this.getEntry(this.index);
        selection_bottom = selection.offsetTop + selection.offsetHeight;
        if (selection_bottom > this.update.scrollTop + this.update.offsetHeight) {
            this.update.scrollTop = this.update.scrollTop + selection.offsetHeight;
        }
    },

    // END OF BLOCK

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

                    var self_id = instance.autocompleter_id;
                    var elem = instance.options.array[i];                    
                    var elem_name = elem[instance.options.search_field];
                    
                    var foundPos = instance.options.ignoreCase ?
                                   elem_name.toLowerCase().indexOf(entry.toLowerCase()) :
                                   elem_name.indexOf(entry);

                    while (foundPos != -1) {

                        if (foundPos == 0 && elem_name.length != entry.length) {
                            var value = "<strong>" + elem_name.substr(0, entry.length) + "</strong>" + elem_name.substr(entry.length);
                            ret.push(
                                    "<li name='" + self_id + "' value='" + i + "'>" + "<div class='main_text'>" + value + "</div>"
                                            + (instance.HINT_FIELD ? ("<div class='hint_text'>" + elem[instance.HINT_FIELD] + "</div>") : "") + "</li>"
                                    );
                            break;

                        } else if (entry.length >= instance.options.partialChars && instance.options.partialSearch && foundPos != -1) {
                            if (instance.options.fullSearch || /\s/.test(elem_name.substr(foundPos - 1, 1))) {
                                var value = elem_name.substr(0, foundPos) + "<strong>" +
                                            elem_name.substr(foundPos, entry.length) + "</strong>" + elem_name.substr(
                                        foundPos + entry.length)

                                partial.push(
                                        "<li name='" + self_id + "' value='" + i + "'>" + "<div class='main_text'>" + value + "</div>"
                                                + (instance.HINT_FIELD ? ("<div class='hint_text'>" + elem[instance.HINT_FIELD] + "</div>") : "") + "</li>"
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

    },

    // NEWLY ADDED INSTANCE METHODS

    validate_item: function(item) {
        // this method is only called for unrecognized items,
        // hence can return 'false' immediately if no unrecognized
        // items are allowed
        switch (this.VALIDATION_TYPE) {
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
    },

    // adds a token to the display list and creates a hidden input to hold the relevant return value
    // for a selected item
    addContactToList: function(item) {
        // clear the input anyway
        this.element.value = "";

        var value_to_add = this.SUGGESTIONS_ARRAY[Element.readAttribute(item, 'value')][this.ID_FIELD];

        // check if such value is not yet added, allow action
        if (this.notYetAdded(value_to_add)) {
            var token = Builder.node('a', {
                "class": 'token',
                "name": this.autocompleter_id,
                href: "#",
                tabindex: "-1"
            },
                    Builder.node('span',
                            Builder.node('span',
                                    Builder.node('span',
                                            Builder.node('span', {},
                                                    [Builder.node('input', { type: "hidden", name: this.autocompleter_id + "_selected_ids[]",
                                                        // NEXT LINE REPLACED TO SUBMIT REQUIRED FIELD OF THE SELECTED OBJECTS, INSTEAD OF BEING FIXED TO EMAILS
                                                        //value: item.lastChild.innerHTML
                                                        value: value_to_add
                                                    }),
                                                        // NEXT LINE REPLACED TO SET TOKEN LABEL TO 'SEARCH_FIELD' CONTENTS INSTEAD OF 'name' AS HARD-CODED SELECTION
                                                        this.SUGGESTIONS_ARRAY[Element.readAttribute(item, 'value')][this.SEARCH_FIELD],
                                                        Builder.node('span', {"class":'x',onmouseout:"this.className='x'",onmouseover:"this.className='x_hover'",
                                                            onclick:"this.parentNode.parentNode.parentNode.parentNode.parentNode.remove(true); return false;"}, " ")
                                                    ]
                                                    )
                                            )
                                    )
                            )
                    );

            $(token).down(4).next().innerHTML = "&nbsp;";
            new Token(token, this.hidden_input);
            this.display_element.insert({before:token});
        }
        else {
            alert('You have already added this value!');
        }
    },

    addUnrecognizedItemToList: function(item) {
        /*   $('autocomplete_input').value = "";*/
        var token = Builder.node('a', {"class":'token',"name":this.autocompleter_id,href:"#",tabindex:"-1"},
                Builder.node('span',
                        Builder.node('span',
                                Builder.node('span',
                                        Builder.node('span', {}, [
                                            Builder.node('input', {type:"hidden", name: this.autocompleter_id + "_unrecognized_items[]",value: item}) ,
                                            item,
                                            Builder.node('span', {"class":'x',onmouseout:"this.className='x'",onmouseover:"this.className='x_hover'",
                                                onclick:"this.parentNode.parentNode.parentNode.parentNode.parentNode.remove(true); return false;"}, " ")
                                        ]
                                                )
                                        )
                                )
                        )
                );        

        $(token).down(4).next().innerHTML = "&nbsp;";
        new Token(token, this.hidden_input);
        this.display_element.insert({before:token});
    },

    // checks if the item with ID == "value" is currently added into the
    // autocomplete text_field
    notYetAdded: function(value) {
        var added_values = this.getRecognizedSelectedIDs();

        for (var i = 0; i < added_values.length; i++)
            if (added_values[i] == value) {
                return(false);
                break;
            }

        return(true);
    },

    // gets an array of item IDs that are currently selected as tokens in the
    // autocomplete field
    getRecognizedSelectedIDs: function() {
        var x = document.getElementsByName(this.autocompleter_id + "_selected_ids[]");

        var res = new Array;
        for (var i = 0; i < x.length; i++)
            res[i] = x[i].value;

        return(res);
    },

    // removes any tokens currently present in the autocomplete text field for the current autocompleter
    deleteAllTokens: function() {
        var x = $$('a.token');
        count = x.length;

        for (var i = count - 1; i >= 0; i--) {
            if (Element.readAttribute(x[i], 'name') == this.autocompleter_id)
                x[i].remove();
        }

        return(count);
    },

    // translates IDs of the items from "item_array" into their corresponding indexes in that
    // array itself
    itemIDsToJsonArrayIDs: function(item_id_array) {
        // array to store the "translated" IDs into the integer IDs of the this.SUGGESTIONS_ARRAY
        var suggestions_array_ids = new Array();
        var cnt = 0;

        var i = 0;
        while ((i < this.SUGGESTIONS_ARRAY.length) && (cnt < item_id_array.length)) {
            if (this.SUGGESTIONS_ARRAY[i][this.ID_FIELD] == item_id_array[cnt]) {
                suggestions_array_ids[cnt] = i;
                cnt++;
            }
            else {
                i++;
            }
        }

        return(suggestions_array_ids);
    },


    // returns a value specified by key "key_name" of an element with
    // ID == "json_array_id" from  "item_array"
    getValueFromJsonArray: function(json_array_id, key_name) {
        return(this.SUGGESTIONS_ARRAY[json_array_id][key_name]);
    },


    // prepopulates the autocomplete token display text box with tokens containing
    // items which have item IDs in "item_id_array"
    prepopulateAutocompleterDisplayWithTokens: function(item_id_array) {
        var suggestions_array_ids = this.itemIDsToJsonArrayIDs(item_id_array);

        var item = null;
        for (var i = 0; i < suggestions_array_ids.length; i++) {
            item = new Element('a', { 'value': suggestions_array_ids[i] });
            this.addContactToList(item);
        }
    }

});


HiddenInput = Class.create({
    initialize: function(element, auto_complete) {
        this.element = $(element);
        this.auto_complete = auto_complete;
        this.auto_complete.hidden_input = this;
        this.auto_complete.prepopulateAutocompleterDisplayWithTokens(this.auto_complete.prepopulate_array);
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
            Event.stop(event); // added to prevent page scroll on mouse clicks

        } else {
            this.deselect();

        }

    },
    detect: function(e) {
        //find the event object
        var eventTarget = e.target ? e.target : e.srcElement;
        var token = eventTarget.token;
        var candidate = eventTarget;
        while (token == null && candidate.parentNode) {
            candidate = candidate.parentNode;
            token = candidate.token;

        }
        return token != null && token.element == this.element;

    }

});


addAction = function(item) {
    autocompleter_id = Element.readAttribute(item, 'name');
    autocompleters[autocompleter_id].addContactToList(item);
}


// ************************************************************************************************************************************

/* Example of simple HTML page using the Advanced Autocompleter: 

 <div id="facebook" class="clearfix">
 <label for="ip_autocomplete_display">To:</label>

 <div tabindex="-1" id="ids" class="clearfix tokenizer" onclick="$('ip_autocomplete_input').focus();" style="width: 340px;">
 <span class="tokenizer_stretcher">^_^</span><span class="tab_stop"><input type="text" id="ip_hidden_input" tabindex="-1" ></span>

 <div id="ip_autocomplete_display" class="tokenizer_input">
 <input type="text" size="1" tabindex="" id="ip_autocomplete_input" />
 </div>
 </div>
 <div id="ip_autocomplete_populate" class="clearfix autocomplete typeahead_list" style="width: 343px; height: auto; overflow-y: hidden;display:none">
 <div class="typeahead_message">Type the name of a friend, friend list, or email address</div>
 </div>

 <br/>
 <a href="" onclick="alert(autocompleters[individual_people_autocompleter_id].getRecognizedSelectedIDs());return(false);">Show all 'id_field' values from selected tokens</a>
 </div>


 <script type="text/javascript">
 var contacts = [ {'name': 'John Smith', 'email': 'john@smith.com', 'id': '1' },
 {'name': 'Joe Bloggs', 'email': 'joe@bloggs.org', 'id': '78' },
 {'name': 'Mike Peters', 'email': 'mike@peters.co.uk', 'id': '131' }  ];
 var prepopulate_with = [1,131];

 var individual_people_autocompleter_id = 'ip_autocompleter';
 var individual_people_autocompleter = new Autocompleter.LocalAdvanced(
 individual_people_autocompleter_id, 'ip_autocomplete_input', 'ip_autocomplete_display', 'ip_autocomplete_populate', contacts, prepopulate_with, {
 frequency: 0.1,
 updateElement: addAction,
 search_field: "name",
 hint_field: "email",
 id_field: "id",
 validation_type: "only_suggested"
 });
 var hidden_input = new HiddenInput('ip_hidden_input',individual_people_autocompleter);

 var autocompleters = new Array();
 autocompleters[individual_people_autocompleter_id] = individual_people_autocompleter;
 </script>

 */

