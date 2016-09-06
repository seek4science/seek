var $j = jQuery.noConflict();

var fixed_prefixes = {
  name_prefix: "sweep[shared_input_values_for_all_runs][inputs_attributes][{{input_number}}]",
  id_prefix: "sweep_shared_input_values_for_all_runs_inputs_attributes_{{input_number}}"
};

var sweep_prefixes = {
  name_prefix: "sweep[runs_attributes][{{iteration_number}}][inputs_attributes][{{input_number}}]",
  id_prefix: "sweep_runs_attributes_{{iteration_number}}_inputs_attributes_{{input_number}}",
  example_value: ""
};

function remove_iteration(el) {
  if($j('.iteration').size() > 1) {
    if(confirm("Are you sure you want to remove this iteration?\n\n"+
               "Any data entered for this iteration will be cleared.")) {
      $j(el).parents('.iteration').remove();
      renumber_iterations();
    }
  } else {
    alert("You must have at least one iteration.");
  }
}

function add_iteration() {
  var iteration_number = Math.round(new Date().getTime());
  var sweepable = $j('input:checkbox:checked.sweep_inputs').map(function () {
    return this.value;
  }).get();

  var input_html = "";
  for(var i = 0; i < sweepable.length; i++) {
    input_html +=
        fill_template(
            fill_template(input_template, sweep_prefixes),
            inputs[sweepable[i]],
            {iteration_number: iteration_number}
        );
  }

  var iteration_html = fill_template(iteration_template, {iteration_number: iteration_number, inputs: input_html});

  $j('#sweep_data').append(iteration_html);
  $j('#fixed_data');
  renumber_iterations();
}

// Re-number the iterations
function renumber_iterations() {
  $j('.iteration_number').each(function (index) {
    $j(this).html(index+1);
  });
}

function fill_template(template, values) {
  for(var i = 1; i < arguments.length; i++) {
    for(var key in arguments[i]) {
      template = template.replace(new RegExp("{{" + key + "}}", "g"), arguments[i][key]);
    }
  }
  return template;
}

$j(document).ready(function () {
  $j('input:checkbox.sweep_inputs').change(function (e) {
    var name = $j(this).val();
    if(this.checked) {
        console.log('checked');
     // It was added
      // Add the new input to existing iterations
      $j('#sweep_data .iteration').each(function () {
        $j(this).append(
            fill_template(
                fill_template(input_template, sweep_prefixes),
                inputs[name],
                {iteration_number: $j(this).data("iteration-number")}
            )
        );
      });

      // Remove it from the fixed data section
      $j('#fixed_data .run_input[data-input-name='+ name +']').remove();
    } else { // It was removed
      if(confirm("Are you sure you no longer want to sweep over '" + name + "'?\n\n"+
                 "Any data you have entered for this input will be cleared")) {
        // Remove the input from existing iterations
        $j('#sweep_data .iteration .run_input[data-input-name='+ name +']').remove();
        // Add the new input to the fixed data section
        $j('#fixed_data').append(
            fill_template(
                fill_template(input_template, fixed_prefixes),
                inputs[name]
            )
        );
      } else {
        return false;
      }
    }
    // Re-arrange the input lists to make sure they're consistent
    $j('#fixed_data').each(function () {
      var run_inputs = $j(this).children('.run_input');
      run_inputs.detach().sort(function(a,b) {
        return inputs[$j(a).data('input-name')].input_number - inputs[$j(b).data('input-name')].input_number;
      });
      $j(this).append(run_inputs);
    });
    $j('#sweep_data .iteration').each(function () {
      var run_inputs = $j(this).children('.run_input');
      run_inputs.detach().sort(function(a,b) {
        return inputs[$j(a).data('input-name')].input_number - inputs[$j(b).data('input-name')].input_number;
      });
      $j(this).append(run_inputs);
    });
  });

  $j('#submit_button').click(function (e) {
    if($j('input:checkbox:checked.sweep_inputs').length < 1) {
      alert("You must select at least one input to sweep over.");
      return false;
    } else {
      return true;
    }
  });

  // Add the initial iteration
  add_iteration();
});
