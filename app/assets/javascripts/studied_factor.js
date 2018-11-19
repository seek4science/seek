var autocompleters = [];

function additionalFieldForItem() {
    var form = $j(this).parents('.condition-or-factor-form');
    var text = $j(':selected', $j(this)).text();

    if (text === 'concentration'){
        $j('.growth_medium_or_buffer_description', form).hide();
        $j('.substance_condition_factor', form).show();
    }
    else if (text === 'growth medium' || text === 'buffer'){
        $j('.substance_condition_factor', form).hide();
        $j('.growth_medium_or_buffer_description', form).show();
    }
    else{
        $j('.substance_condition_factor', form).hide();
        $j('.growth_medium_or_buffer_description', form).hide();
    }
}

function resetMeasuredItemSelects() {
    $j('.measured-item-select').each(function () {
        additionalFieldForItem.apply(this);
    })
}
$j(document).ready(function () {
    $j(document).on('change', '.measured-item-select', additionalFieldForItem);
    resetMeasuredItemSelects();
});
