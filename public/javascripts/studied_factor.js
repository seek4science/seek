var autocompleters = new Array();

function showOrHideSubstanceTextField(form_id){
    var elements =  $(form_id).getElements();
    var item;
    var substance_autocomplete;
    for (var i=0;i<elements.length;i++)
    {
      var id = elements[i].id;
      if (id.match('measured_item_id'))
        item = elements[i];
      if (id.match('autocomplete_input'))
        substance_autocomplete = elements[i];
    }

    //check if the selected item is concentration
    var selectedIndex = item.selectedIndex;
    var option_select = item.options[selectedIndex];

    if (option_select.text == 'concentration'){
        substance_autocomplete.disabled = false;
        if (form_id == 'add_condition_or_factor_form')
         Effect.Appear('add_substance_concentration',{ duration: 2});

    }else{
        //clear all the substances when disable
        var autocompleter_id = substance_autocomplete.id.replace('autocomplete_input', '');
        autocompleter_id = autocompleter_id.concat('autocompleter');
        autocompleters[autocompleter_id].deleteAllTokens();
        substance_autocomplete.disabled = true;
        if (form_id == 'add_condition_or_factor_form')
          Effect.Fade('add_substance_concentration', { duration: 1 });
    }
}

function searchSubstanceInformation(){
    var known_substances = document.getElementsByName("substance_autocompleter_selected_ids[]")
    var unrecognized_substances = document.getElementsByName("substance_autocompleter_unrecognized_items[]")
    //take the info from internal for the known_substances

    //web service to retrieve the info for the unrecognized_substances
}
function testAjax(){
    new Ajax.Request('http://hitssv506.h-its.org/sabioRestWebServices/suggestions/compounds?searchCompounds=water', {
      method: 'GET',
      onSuccess: function(transport) {
        alert('sucess')
        alert(transport.responseText)

      },
      onFailure: function(){ alert('Something went wrong...') }
    });
}
