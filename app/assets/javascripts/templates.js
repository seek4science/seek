var Templates = {
  table: null,
  context: { description_elem: null, suffix: null, field_name: null }
};

Templates.clearContext = function () {
  Templates.context = { description_elem: null, suffix: null, field_name: null };
};

Templates.init = function (elem) {
  const columnDefs = [
    { orderable: false, targets: [0, 7, 11] },
    {
      targets: [3, 4, 9, 10],
      visible: false,
      searchable: false
    },
    { defaultContent: "-", targets: "_all" }
  ];

  const columns = [
    {
      title: "Required",
      width: "5%",
      className: "text-center",
      mRender: function (data, type, full) {
        return `<td><input class='template-input' ${
          data ? "disabled checked" : ""
        } type='checkbox' onClick='handleClick(this)'/></td>`;
      }
    },
    { title: "Attribute name", width: "18%" },
    { title: "Description", width: "40%" },
    { title: "attribute_type_id" },
    { title: "cv_id" },
    { title: "Unit", width: "5%" },
    { title: "Data type", width: "10%" },
    {
      title: "Is title",
      className: "text-center",
      mRender: function (data) {
        return `<td><input class='template-input' disabled ${data ? "checked" : ""} type='checkbox' /></td>`;
      },
      width: "7%"
    },
    { title: "PID", width: "10%" },
    { title: "pos" },
    { title: "isa_tag_id" },
    {
      title: "Remove",
      width: "5%",
      className: "text-center",
      mRender: function (data, type, full) {
        return full[0]
          ? ""
          : '<a class="btn btn-danger btn-sm" href="javascript:void(0)" onClick="remove(this)">Remove</a>';
      }
    }
  ];

  Templates.table = elem.DataTable({
    columnDefs,
    columns,
    order: [[9, "asc"]],
    autoWidth: false,
    stateSave: false
  });

  loadFilterSelectors(templates);
  loadTemplates(templates);
  setTemplate();
};

const remove = (e) =>{
  const currentPage = Templates.table.page()
  Templates.table.row($j(e).closest("tr")).remove().draw();
  Templates.table.page(currentPage).draw(false);
}
const handleClick = (e) => (Templates.table.row($j(e).closest("tr")).data()[0] = $j(e).is(":checked"));

function loadTemplates(data) {
  $j("#source_select").empty();
  let categorized = data.reduce((obj, item) => {
    obj[item.group] = obj[item.group] || [];
    obj[item.group].push(item);
    return obj;
  }, {});


  $j.each(Object.keys(categorized), (i, key) => {
    const elem = $j(`<optgroup label=${key}></optgroup>`);
    
    $j.each(categorized[key], (j, sub_item) => {
      elem.append(
        $j(`<option>${sub_item.title}</option>`).attr("value", sub_item.template_id).text(key.title)
      );
    });
    $j("#source_select").append(elem);
  });
  setTemplate();
}

function setTemplate() {
  Templates.table.clear();
  const id = $j("#source_select").find(":selected").val();
  const data = templates.find((t) => t.template_id == id);
  Templates.table.rows.add(Templates.mapData(data.attributes)).draw();
}

Templates.mapData = (data) =>
  data.map((item) => [
    item.required,
    item.title,
    item.description,
    item.attribute_type_id,
    item.cv_id,
    item.unit_id,
    item.data_type,
    item.is_title,
    item.pid,
    item.pos,
    item.isa_tag_id
  ]);

function loadFilterSelectors(data) {
  $j.each($j("select[id^='templates_']"), (i, elem) => {
    const key = elem.getAttribute("data-key");
    
    // Gets the set of values to choose from per data-key
    let dt = [...new Set(data.map((item) => item[key]))];
    // If the key == level => options should be filtered out, depending on the 'field_name' context.
    // If field_name == null, the button was clicked from the new Template form and all options should be present.
    if (key === "level" && Templates.context.field_name !== null) {
      if(Templates.context.field_name === 'sample_collection_sample_type'){
        dt = dt.filter(lvl => lvl === "study sample")
      } else if(Templates.context.field_name === 'source_sample_type'){
        dt = dt.filter(lvl => lvl === "study source")
      } else if(Templates.context.field_name === 'sample_type') {
        dt = dt.filter(lvl => lvl === "assay")
      }
      $j(elem).find("option").remove(); // Removes all options, even the first, i.e. "not selected"
    }
    else {
      $j(elem).find("option").not(":first").remove(); // Removes all options, but keeps the first one (="not selected")
    }

    $j.each(dt, (i, item) => $j(elem).append(`<option value="${item}">${item}</option>`)); // Adds the options to the select items
    $j(elem).on("change", function () {
      const filters =  $j("[data-key]")
        .map((i, elem) => ({ key: elem.getAttribute("data-key"), value: elem.value }))
        .toArray()
        .filter((f) => f.value != "not selected");
      let filtered = templates;
      filters.forEach(({ key, value }) => {
        filtered = filtered.filter((x) => x[key] == value);
      });
      loadTemplates(filtered || templates);
    });
  });
}

const applyTemplate = () => {
  const id = $j("#source_select").find(":selected").val();
  const data = templates.find((t) => t.template_id == id);
  const codeMirror = $j(Templates.context.description_elem || "#template-description").nextAll(
    ".CodeMirror"
  )[0].CodeMirror;
  if (data.description) codeMirror.getDoc().setValue(data.description);
  const suffix = Templates.context.suffix || "";
  const attribute_table = "#attribute-table" + suffix;
  const attribute_row = "#new-attribute-row" + suffix;
  const addAttributeRow = "#add-attribute-row" + suffix;

  $j(`${attribute_table} tbody`).find("tr:not(:last)").remove();
  SampleTypes.unbindSortable();
  // Make sure default sorted attributes are added to the table 
  Templates.table.order([9, "asc"]).draw();
  $j.each(Templates.table.rows().data(), (i, row) => {
    var newRow = $j(`${attribute_row} tbody`).clone().html();
    var index = 0;
    $j(`${attribute_table} tr.sample-attribute`).each(function () {
      var newIndex = parseInt($j(this).data("index"));
      if (newIndex > index) {
        index = newIndex;
      }
    });
    index++;

    newRow = $j(newRow.replace(/replace-me/g, index));

    $j(newRow).find('[data-attr="required"]').prop("checked", row[0]);
    $j(newRow).find('[data-attr="title"]').val(row[1]);
    $j(newRow).find('[data-attr="description"]').val(row[2]);
    $j(newRow).find('[data-attr="type"]').val(row[3]);
    $j(newRow).find('[data-attr="cv_id"]').val(row[4]);
    $j(newRow).find('[data-attr="unit"]').val(row[5]);
    $j(newRow).find(".sample-type-is-title").prop("checked", row[7]);
    $j(newRow).find('[data-attr="pid"]').val(row[8]);
    $j(newRow).find('[data-attr="isa_tag_id"]').val(row[10]);

    // Show the CV block if cv_id is not empty
    if (row[4]) $j(newRow).find(".controlled-vocab-block").show();

    // Show the sample-type-block block if type is SEEK sample
    const is_seek_sample = $j(newRow)
      .find(".sample-type-attribute-type")
      .find(":selected")
      .data("is-seek-sample");
    if (is_seek_sample) {
      // Select the first item by default and hide the row
      $j(newRow).find(".linked-sample-type-selection optgroup option:first").attr("selected", "selected");
      $j(newRow).hide();
    }

    $j(`${attribute_table} ${addAttributeRow}`).before(newRow);
  });

  // Sets the template_id in the form (if the object is an isa_study form sample_type)
  const template_id_tag = $j(`#isa_study${suffix}template_parent_id`);
  if (template_id_tag) $j(template_id_tag).val(id);

  SampleTypes.recalculatePositions();
  SampleTypes.bindSortable();
	$j(".sample-type-attribute-type").trigger("change", [false]);
};

// Shows the modal form
const showTemplateModal = () => {
  loadFilterSelectors(templates);
  updateTypeSelect(Templates.context.field_name);
  $j("#existing_templates").modal("show");
};

// Selects the right option, depending on the 'field_name' that was passed from the form.
const updateTypeSelect = function(field_name) {
  if(field_name === 'sample_collection_sample_type'){
		$j("#templates_type_select").val("study sample").change();
  } else if (field_name === 'source_sample_type') {
		$j("#templates_type_select").val("study source").change();
  } else if(field_name === 'sample_type') {
    $j("#templates_type_select").val("assay").change();
  } else {
    $j("#templates_type_select option").first().change();
  }
};

const initSelect2 = (elem, parentElem)=>{
	elem.select2({
		theme: "bootstrap",
		escapeMarkup: function(markup) {
			return markup;
		},
		templateResult: function(data) {
			return data.id ? `${data.text} <em>(id: ${data.id})</em>` : data.text;
		},
		dropdownParent: parentElem
	});
}
