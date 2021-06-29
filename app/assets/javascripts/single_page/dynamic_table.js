function load_samples(cls) {
  let params = {};
  params.onSuccess = (res) => {
    if (!res.data) return;
    // Remove link_id for now --> Is it needed in the future??
    // const header = $j.grep(res.data.header, (n, i) => n.title != "link_id")
    // console.log("res.data.header", res.data.header);
    // console.log("res.data.samples", res.data.samples);

    //TO_DO
    // Delete link_id from attributes & add it as a column in samples
    // Then send it in res.data.samples body
    // Q: Why? A: The user defined columns will appear after the link_id column

    loadSampleTableHeader(res.data.header, cls);
    loadSampleData(res.data.samples, res.data.header, cls);
    hideAttributes(cls);
    validateCells(cls);
  };
  ajaxCall(`/projects_folders/${pid}/sample_table/${selectedItem.id}`, "GET", params);
}

function loadSampleTableHeader(headers, tableClass) {
  // Adds the select column
  const headTr = $j(`${tableClass} .downHeader`);
  headTr.empty().append("<th><input id='selectAll' onClick='selectAll(this)' type='checkbox'/></th>");
  //   const TH = customTD(x.sample_controlled_vocab_id, x.title, x.required, x.sample_type_id);
  $j(headers).each((i, x) => {
    //x ==> sampleAttribute
    let params = {};
    params.id = x.id;
    params.title = x.title;
    params.required = x.required;
    params.sample_type_id = x.sample_type_id;
    params.sample_controlled_vocab_id = x.sample_controlled_vocab_id;
    // console.log(params);
    const TH = customTD(params);
    headTr.append(TH);
  });
  $j(`${tableClass} .topHeader th`).attr("colspan", headers.length + 1);
}

function loadSampleData(data, headers, cls) {
  $j(cls + " tbody").empty();
  const rows = consolidateSamples(data);
  $j(rows).each((i, row) => {
    let newRow = "<td><input type='checkbox'/></td>";

    $j.each(headers, (i, x) => {
      newRow += findSampleVal(row, x);
    });

    $j(cls + " tbody").append(`<tr>` + newRow + "</tr>");
  });
  // Set the Auto Complete
  $j.each($j(cls + " tbody tr td:not(:first-child)"), (i, k) => {
    const sample_controlled_vocab_id = $j(cls + ` .downHeader th:nth-child(${$j(k).index() + 1})`).attr(
      "sample_controlled_vocab_id"
    );
    setAutoComplete(k, sample_controlled_vocab_id);
  });
}

function findSampleVal(row, key) {
  let sampleId = "";
  let text = "";
  $j.each(row, (n, samplePart) => {

    if (key.sample_type_id == samplePart.sampleTypeid) {
      text = samplePart.data[key.title];
      sampleId = samplePart.sampleId;
      return;
    }
  });
  return `<td contenteditable data-sampleid=${sampleId}>${text}</td>`;
}

function consolidateSamples(data) {
  const sourceSamples = data[0];
  delete data[0];
  let rows = [];
  $j(sourceSamples).each((i, row) => {
    let tableRow = [
      {
        sampleId: row.id,
        data: JSON.parse(row.json_metadata),
        sampleTypeid: row.sample_type_id,
        // link_id: row.link_id,
      },
    ];
    $j(Object.keys(data)).each((j, x) => {
      // TO_DO: check the following code in case of more sample existance
      // TO_DO: Get sourceSamples Link_id and search it in other records... : Samples are sorted based on their sample_type > assay position
      if (data[x][i]) {
        tableRow.push({
          sampleId: data[x][i].id,
          data: JSON.parse(data[x][i].json_metadata),
          sampleTypeid: data[x][i].sample_type_id,
        });
      } else {
        tableRow.push({
          sampleId: "",
          data: {},
          sampleTypeid: "",
        });
      }
    });
    rows.push(tableRow);
  });
  return rows;
}

function validateCells(cls) {
  // Checks which cells are rquired and not filled yet
  let valid = true;
  const required = $j.map($j(cls + " .downHeader th").get(), (x, i) => !x.children.length > 0);
  const rows = $j(cls + " tbody tr").get();
  $j.each(rows, (i, row) => {
    if (!$j(row).attr("delete")) {
      const tds = $j(row).find("td").get();
      $j.each(tds, (j, td) => {
        if (required[j] && $j(td).html() == "") {
          $j(td).addClass("errorCell");
          valid = false;
        } else {
          $j(td).removeClass("errorCell");
        }
      });
    }
  });
  return valid;
}

function saveSamples(cls) {
  if (!validateCells(cls)) {
    alert("Please fill the required fields.");
    return;
  }
  // Get the new list of sample types and samples with their attributes
  let header = $j(cls + " .downHeader th");
  const _sampleTypes = $j.map(header.slice(1), (x, i) => ({
    sampleAttributeId: $j(x).attr("sampleattributeid"),
    sampleTypeId: $j(x).attr("data-sampletypeid"),
    text: getPlainText($j(x).html()),
  }));
  // Get all the rows of the table
  const rows = $j(cls + " tbody tr").get();
  let samples = [];
  for (let i = 0; i < rows.length; i++) {
    samples.push(...splitSamples(rows[i], _sampleTypes));
  }
  //----------------SAMPLE_TYPES UPDATE-----------------
  const sampleTypes = getSampleTypes(_sampleTypes);
  updateSampleType(sampleTypes); // Will the jsonp_metadata of samples be updated automatically??
  //----------------SAMPLES UPDATE-----------------
  const updateSamples = $j.grep(samples, (x) => x.sampleId && !x.delete);
  console.log("updateSamples", updateSamples);
  // TO-DO: Update the editted samples only
  updateSample(updateSamples);
  //----------------SAMPLES CREATE-----------------
  const createSamples = $j.grep(samples, (x) => !x.sampleId && !x.delete);
  console.log("createSamples", createSamples);
  createBatchSample(createSamples)
  //----------------SAMPLES DELETE-----------------
  const deleteSamples = $j.grep(samples, (x) => x.delete && x.sampleId);
  console.log("deleteSamples", deleteSamples);
  deleteSample(deleteSamples);
}

function getSampleTypes(a) {
  let s = [];
  for (let i = 0; i < a.length; i++) {
    const item = a[i];
    const attribute = { title: item.text, sampleAttributeId: item.sampleAttributeId };
    if (s.length == 0 || item.sampleTypeId != s[s.length - 1].id) {
      s.push({
        id: item.sampleTypeId,
        attributes: [attribute],
      });
    } else {
      s[s.length - 1].attributes.push(attribute);
    }
  }
  return s;
}

function splitSamples(row, header) {
  let samples = [];
  // Apply the row link_id to all samples in the row
  const link_id = $j(row).attr("link_id");
  // consider select column
  $j.each($j(row).find("td").slice(1), (i, td) => {
    if (samples.length == 0 || header[i].sampleTypeId != samples[samples.length - 1].sampleTypeId) {
      samples.push({
        sampleId: $j(td).attr("data-sampleid"),
        sampleTypeId: header[i].sampleTypeId,
        JSONMetadata: {
          [`${header[i].text}`]: $j(td).html(),
        },
        delete: $j(td).parent().attr("delete") ? true : false,
        link_id,
      });
    } else {
      $j.extend(true, samples[samples.length - 1].JSONMetadata, {
        [`${header[i].text}`]: $j(td).html(),
      });
    }
  });
  return samples;
}

function updateSampleType(sampleTypes) {
  console.log("sampleTypes", sampleTypes);
  $j.each(sampleTypes, (k, sampleType) => {
    // New sampleAttributeTypes don't need id (Create)
    // Old sampleAttributeTypes need id (update)
    const attributeMap = $j.map(sampleType.attributes, (x, i) => {
      // new attribute
      if (!x.sampleAttributeId)
        return {
          title: x.title,
          sample_attribute_type: {
            id: "8",
          },
        };
    });
    const data = updateSampleTypeStruct(attributeMap);
    console.log(data);
    let params = {};
    params.onSuccess = (s) => console.log("sampleType was updated successfully! : " + s.data.id);
    params.onError = (e) => console.log(e);
    params.data = JSON.stringify(data);
    ajaxCall("/sample_types/" + sampleType.id, "PUT", params);
  });
}

function updateSample(samples) {
  $j.each(samples, (k, sample) => {
    let params = {};
    params.onSuccess = (s) => console.log("The sample was updated successfully! : " + s.data.id);
    params.onError = (e) => console.log(e);
    const data = updateSampleStruct(sample.JSONMetadata);
    params.data = JSON.stringify(data);
    ajaxCall("/samples/" + sample.sampleId, "PUT", params);
  });
}

function createBatchSample(samples) {
  let data = [];
  $j.each(samples, (k, sample) => {
    data.push(batchSampleCreateStruct(k, sample.JSONMetadata, sample.sampleTypeId, sample.link_id, pid));
  });
  let params = {};
  params.onSuccess = (s) => {
    console.log("Batch sample create result: " + s.data);
  };
  params.onError = (e) => console.log(e);
  params.data = JSON.stringify(data);
  ajaxCall("/samples/batch_create/", "POST", params);
}

function createSample(samples) {
  $j.each(samples, (k, sample) => {
    let data = createSampleStruct(sample.JSONMetadata, sample.sampleTypeId, sample.link_id, pid);
    let params = {};
    params.onSuccess = (s) => console.log("The sample was created successfully! : " + s.data.id);
    params.onError = (e) => console.log(e);
    params.data = JSON.stringify(data);
    ajaxCall("/samples/", "POST", params);
  });
}

function deleteSample(samples) {
  $j.each(samples, (k, sample) => {
    let params = {};
    params.onSuccess = () => console.log("The sample was deleted successfully!");
    params.onError = () => alert("An error occurred when deleting the sample");
    ajaxCall("/samples/" + sample.sampleId, "DELETE", params);
  });
}

function addCustomCol(table, bias, text = "") {
  if (text.length == 0) text = $j.trim($j(".customCol").val());
  $j(".arrow_box").css({
    display: "none",
  });
  let options = {};
  options.title = text;
  options.tableClass = table;
  options.bias = bias;
  addColumn(options);

  hideAttributes(table);
}

function addRow(table) {
  let newRow = "<td><input type='checkbox'/></td>";
  let link_id = uuidv4();
  $j(table + " .downHeader")
    .find("th")
    .each(function (k, v) {
      // Skips the select column
      k > 0 && (newRow += "<td contenteditable></td>");
    });
  $j(table + " tbody").append(`<tr link_id=${link_id} data-new="true">${newRow}</tr>`);
  // Set the Auto Complete
  $j.each($j(table + " tbody tr:last td:not(:first-child)"), (i, k) => {
    const sample_controlled_vocab_id = $j(k)
      .closest("table")
      .find("th")
      .eq($j(k).index())
      .attr("sample_controlled_vocab_id");
    setAutoComplete(k, sample_controlled_vocab_id);
  });
  hideAttributes(table);
}

function uuidv4() {
  return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, function (c) {
    var r = (Math.random() * 16) | 0,
      v = c == "x" ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

function update_method(std_id, asy_id, content) {
  let params = {};
  params.data = { std_id, asy_id, content };
  params.onSuccess = () => alert("Content saved successfully!");
  params.onError = (e) => alert("Error " + e);
  ajaxCall(pid + "/update_method", "PATCH", params);
}

function setAutoComplete(e, sample_controlled_vocab_id) {
  $j(e).bind("keyup", function (event) {
    AutoComplete(e, sample_controlled_vocab_id);
  });
}

function AutoComplete(e, sample_controlled_vocab_id) {
  const setSource = (data) => {
    $j(e).autocomplete({
      classes: {
        "ui-autocomplete": "highlight",
      },
      source: data || [],
      mustMatch: true,
    });
  };
  let params = {};
  let url = "/projects_folders/" + pid + "/ontology?sample_controlled_vocab_id=";
  url += sample_controlled_vocab_id + "&query=" + $j(e).html();
  params.onComplete = (jqXHR, textStatus) => {
    const data = jqXHR.responseJSON.data;
    setSource(data);
    $j(e).autocomplete("search", "a");
  };
  params.onError = (e) => console.log(e);
  params.dataType = "json";
  ajaxCall(url, "GET", params);
}

function selectAll(e) {
  const checkBoxes = $j(e).closest("table").find("tr td:first-child input");
  $j.each(checkBoxes, (i, k) => {
    k.checked = e.checked;
  });
}

function deselectAll(e) {
  const checkBoxes = $j(e).closest("table").find("tr td:first-child input");
  $j.each(checkBoxes, (i, k) => {
    k.checked = false;
  });
}

function hideAttributes(cls) {
  let colSpan = -1;
  let itemCounter = 0;
  const hiddenAttrs = VM("", "attribs").get();
  const hiddenSampleTypes = VM("", "sampleTypes").get();
  $j(cls + " .topHeader")
    .empty()
    .append(`<th colspan=1></th>`);
  let prevSampleTypeId = $j(cls + " .downHeader th:nth-child(2)").attr("data-sampletypeid");
  const headerCount = $j(cls + " .downHeader th").length - 1;
  $j.each($j(cls + " .downHeader th"), (i, th) => {
    const title = getPlainText($j(th).html());
    const sampleTypeId = $j(th).attr("data-sampletypeid");
    const condition = hiddenAttrs.includes(title) || hiddenSampleTypes.includes(sampleTypeId);
    !condition && colSpan++;
    hideCells(cls, condition, th);
    if (i > 0 && (sampleTypeId != prevSampleTypeId || i == headerCount)) {
      $j(th).addClass("tableSeparate");
      addTopHeaderCell(cls, colSpan, prevSampleTypeId, itemCounter);
      colSpan = 0;
      itemCounter++;
      const status = hiddenSampleTypes.includes(prevSampleTypeId) ? false : true;
      $j(cls + " .topHeader th")
        .eq(itemCounter)
        .find("input")
        .attr("checked", status);
      $j.each($j(cls + " tbody tr"), (i, tr) => {
        $j(tr)
          .find(`td:eq(${$j(th).index()})`)
          .addClass("tableSeparate");
      });
      prevSampleTypeId = sampleTypeId;
    }
  });
}

function getPlainText(html) {
  return $j.trim(html.replace(/<a( |>).*?<\/a>/gi, ""));
}

function hideCells(cls, condition, cell) {
  $j.each($j(cls + " tbody tr"), (i, tr) => {
    const v = $j(tr).find(`td:eq(${$j(cell).index()})`);
    if (condition) v.hide();
    else v.show();
  });
  if (condition) $j(cell).hide();
  else $j(cell).show();
}

function addTopHeaderCell(cls, colSpan, sampleTypeId, itemCounter) {
  let element = `<th class="headerSeparator" colspan=${colSpan}>`;
  element += `<input type='checkbox' onchange="toggleSampleType(${sampleTypeId}, '${cls}')"/>`;
  element += `${itemCounter == 0 ? "Source " : "Assay " + itemCounter}</th>`;
  $j(cls + " .topHeader").append(element);
}

function hideOptionalAttrs(cls) {
  $j.each($j(cls + " .downHeader th"), (i, th) => {
    const optional = $j(th).attr("optional");
    const title = getPlainText($j(th).html());
    if (optional == "true") {
      $j.each($j(cls + " tbody tr"), (i, tr) => {
        $j(tr)
          .find(`td:eq(${$j(th).index()})`)
          .hide();
      });
      $j(th).hide();
      VM(title, "attribs").hide();
      //   manageVisibility("hide", title);
    }
  });
  hideAttributes(cls);
}

function toggleSampleType(id, cls) {
  //   manageVisibility("toggle", id, "sampleTypes");
  VM(id, "sampleTypes").toggle();
  hideAttributes(cls);
}

function deleteSampleClick(cls) {
  if (confirm("Are you sure you want to delete the selected samples?")) {
    const selectedSamples = $j(cls + " tbody tr td:first-child");

    $j.each(selectedSamples, (i, k) => {
      if ($j(k).find("input")[0].checked) {
        $j(k).parent().attr("delete", true);
        $j.each($j(k).parent().find("td"), (j, v) => {
          $j(v)
            .attr("contenteditable", false)
            .css("background-color", "#cfcfcf")
            .css("border-color", "#b5b5b5")
            .css("text-decoration", "line-through");
        });
      }
    });
    deselectAll(this);
  }
}

function showPreDefinedCols(tblClass, bias) {
  $j(".arrow_box").toggle();
  $j(".arrow_box").position({
    my: "left top",
    at: "right+12 top-10",
    of: $j(event.target),
    collision: "fit",
  });
  $j("#btn_custom_col").attr("onclick", `addCustomCol('${tblClass}','${bias}')`); // Custom Input
  $j("#preDefinedList li:not(:first-child)").remove();
  $j.each($j(`${tblClass} thead tr:nth-child(2) th:hidden`), (i, x) => {
    const title = $j.trim(
      $j(x)
        .html()
        .replace(/<a( |>).*?<\/a>/gi, "")
    );
    $j("#preDefinedList").append(`<li><input type="button" class="btn btn-primary col-md-12 predef"
           onClick= "addCustomCol('${tblClass}','${bias}','${title}')" value="${title}"></li>`);
  });
}

function addColumn(options) {
  let colCount = $j(`${options.tableClass} thead tr:nth-child(2) th`).length;
  let thIndex = -1;
  let existingCol = false;
  $j.each($j(options.tableClass + " thead tr:nth-child(2) th:hidden"), (i, k) => {
    if (getPlainText($j(k).html()) == options.title) {
      $j(k).show();
      console.log($j(k));
      thIndex = $j(k).index();
      existingCol = true;
      return false;
    }
  });
  // If no hidden th found, then add new column
  if (!existingCol) {
    //Previous call sample type id
    const sampletypeid = $j(options.tableClass + ` .downHeader th:last-child`).data("sampletypeid");
    let action =
      "<a href='' onclick='remove_col(event)'> <span class='glyphicon glyphicon-trash'></span></a>";
    let element = `<th data-sampletypeid="${sampletypeid}" sample_controlled_vocab_id="" optional="true">${options.title} ${action}</th>`;
    $j(options.tableClass + ` thead tr:nth-child(2) th:nth-child(${colCount})`).before(element);
    //data-sampletypeid
    //increase first header last td colspan
    const firstHeader = $j(options.tableClass + " .topHeader th:last-child");
    firstHeader.attr("colspan", +firstHeader.attr("colspan") + 1);
  }

  $j(options.tableClass + " tbody")
    .find("tr")
    .each(function () {
      if (existingCol) $j(this).find("td").eq(thIndex).show();
      else {
        //data-sampleid
        const sampleid = $j(this).find(`td:last-child`).data("sampleid");
        $j(this)
          .find(`td:nth-child(${colCount})`)
          .before(`<td contentEditable='true' sampleid='${sampleid}'></td>`);
      }
    });

  if (options.title.length > 0) VM(options.title, "attribs").unhide(); //manageVisibility("unhide", options.title);
}

function customTD(params) {
  const { id, sample_controlled_vocab_id, title, required, sample_type_id } = params;
  const action = required
    ? ""
    : "<a href='' onclick='remove_col(event)'> <span class='glyphicon glyphicon-trash'></span></a>";
  return (
    `<th sampleAttributeId=${id} data-sampletypeid=${sample_type_id} optional=${!required}` +
    ` sample_controlled_vocab_id="${sample_controlled_vocab_id}">${title} ${action}</th>`
  );
}

function remove_col(e) {
  event.preventDefault();
  if (confirm("Do you really want to delete the column?")) {
    if ($j(e.target).closest("tr").find("th").length == 2) {
      alert("Can not remove column. \nThere sould be at least one column.");
      return;
    }
    let th = $j(e.target).closest("th");
    $j(e.target)
      .closest("table")
      .find("tbody tr")
      .each(function (i, tr) {
        $j(tr).find(`td:eq(${th.index()})`).hide();
      });
    th.hide();

    // manageVisibility("hide", getPlainText(th.html()));
    VM(getPlainText(th.html()), "attribs").hide();
  }
}

function addSourcesOptions() {
  $j("#sourceSelect").empty();
  $j.each(characteristics, (key, value) => {
    $j("#sourceSelect").append(
      $j("<option></option>")
        .attr("value", key)
        // .attr("sampleCVId", value.sampleCVId)
        .text(value.title)
    );
  });
}

function sourceChange() {
  let i = $j("#sourceSelect").val();
  $j("#sourceAttribs tbody").empty();
  $j("#sourceSelect").val(i);
  $j.each(characteristics[i].attributes, (k, attr) => {
    const newRow = attr.required
      ? "<td><input disabled checked type='checkbox'/></td>"
      : "<td><input type='checkbox'/></td>";
    let title = attr.required ? "<strong>" + attr.title + "*" + "</strong>" : attr.title;
    $j("#sourceAttribs tbody").append(
      `<tr>${newRow}<td>${title}</td><td>${attr.shortName}</td><td>${attr.des}</td></tr>`
    );
  });
  loadSampleTableHeader(characteristics[sourceSelect.value].attributes, ".sourceSampleTable");

  deselectAll(this);
}

function createSampleType(data, cb) {
  let params = {};
  params.onSuccess = (s) => cb(s);
  params.onError = (e) => console.log(e);
  params.data = JSON.stringify(data);
  ajaxCall("/sample_types/", "POST", params);
}

function sampleTypeData(attributes, title, assayId = null) {
  // Create the Source Sample Type
  // Add table columns as attribute types
  const attributeMap = $j(attributes)
    .map((i, x) => ({
      title: x.title.toLowerCase(),
      sample_attribute_type: {
        id: "18",
      },
      sample_controlled_vocab_id: x.id,
      required: x.required,
      pos: (i + 1).toString(),
      unit_id: null,
      is_title: i == 0 ? true : false,
    }))
    .get();
  return createSampleTypeStruct(title, "", attributeMap, pid, assayId);
}

function saveDesign() {
  const callBack = (s) => {
    let data = { flowchart: {} };
    data.flowchart.study_id = selectedItem.id;
    data.flowchart.source_sample_type_id = s.data.id;
    data.flowchart.items = '[{"id": "", "left": 40, "top": 100}]';

    let params = {};
    params.onSuccess = (s) => loadFlowchart();
    params.onError = () => hideFlowchart();
    params.data = JSON.stringify(data);
    ajaxCall(`/projects_folders/${pid}/update_flowchart`, "POST", params);
  };
  let attr = characteristics[$j("#sourceSelect").children("option:selected").val()].attributes;
  const title = `${$j("#std-title span").html()}_source_sample_type`;
  createSampleType(sampleTypeData(attr, title), callBack);
}

// loads sample source table header
function loadDesign() {
  let params = {};
  params.onSuccess = (s) => {
    if (s.data) loadSampleTableHeader(s.data, ".sourceSampleTable");
    else sourceChange();
  };
  params.onError = (e) => console.error(e);
  params.dataType = "json";
  ajaxCall(`/projects_folders/${pid}/sample_source/${selectedItem.id}`, "GET", params);
}
