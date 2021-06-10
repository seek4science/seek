let existingAssays = [];
let AssayDetails = [];
const init_flowchart = () => {
  var $flowchart = $j("#chart_canvas");
  var $container = $flowchart.parent();
  // var cx = $flowchart.width() / 2;
  // var cy = $flowchart.height() / 2;
  // var currentZoom = 0.5;
  // Apply the plugin on a standard, empty div...
  var $operatorProperties = $j("#operator_properties");
  var $linkProperties = $j("#link_properties");
  var $operatorTitle = $j("#operator_title");
  var $linkColor = $j("#link_color");
  $flowchart.flowchart({
    onOperatorSelect: function (operatorId) {
      $operatorProperties.show();
      $operatorTitle.val($flowchart.flowchart("getOperatorTitle", operatorId));
      $operatorProperties.css("position", "absolute");
      $operatorProperties.css("left", this.data.operators[operatorId].left - 28);
      $operatorProperties.css("top", this.data.operators[operatorId].top - 42);
      return true;
    },
    onOperatorUnselect: () => {
      // $operatorProperties.hide();
      // return true;
    },
    onLinkSelect: (linkId) => {
      $linkProperties.show();
      $linkColor.val($flowchart.flowchart("getLinkMainColor", linkId));
      return true;
    },
    onLinkUnselect: () => {
      $linkProperties.hide();
      return true;
    },
  });

  $operatorTitle.keyup(() => {
    var selectedOperatorId = $flowchart.flowchart("getSelectedOperatorId");
    if (selectedOperatorId != null) {
      $flowchart.flowchart("setOperatorTitle", selectedOperatorId, $operatorTitle.val());
    }
  });
  $j(".delete_selected_button").click(() => {
    $flowchart.flowchart("deleteSelected");
    $j("#operator_properties").hide();
  });
  var $draggableOperators = $j(".draggable_operator");

  const getOperatorData = ($element) => {
    const nbInputs = parseInt($element.data("nb-inputs"));
    const nbOutputs = parseInt($element.data("nb-outputs"));
    var data = {
      properties: {
        title: $element.text(),
        inputs: {},
        outputs: {},
        shape: $element.data("shape"),
        shape_id: $element.data("shape_id"),
      },
    };
    var i = 0;
    for (i = 0; i < nbInputs; i++) {
      data.properties.inputs["input_" + i] = {
        label: "Input " + (i + 1),
      };
    }
    for (i = 0; i < nbOutputs; i++) {
      data.properties.outputs["output_" + i] = {
        label: "Output " + (i + 1),
      };
    }
    return data;
  };
  // var operatorId = 0;
  $draggableOperators.draggable({
    cursor: "move",
    opacity: 0.7,
    // helper: "clone",
    appendTo: "body",
    zIndex: 1000,
    helper: function (e) {
      let $this = $j(this);
      let data = getOperatorData($this);
      return $flowchart.flowchart("getOperatorElement", data);
    },
    stop: function (e, ui) {
      let $this = $j(this);
      let elOffset = ui.offset;
      let containerOffset = $container.offset();
      if (
        elOffset.left > containerOffset.left &&
        elOffset.top > containerOffset.top &&
        elOffset.left < containerOffset.left + $container.width() &&
        elOffset.top < containerOffset.top + $container.height()
      ) {
        let flowchartOffset = $flowchart.offset();
        let relativeLeft = elOffset.left - flowchartOffset.left;
        let relativeTop = elOffset.top - flowchartOffset.top;
        let positionRatio = $flowchart.flowchart("getPositionRatio");
        relativeLeft /= positionRatio;
        relativeTop /= positionRatio;
        let data = getOperatorData($this);
        data.left = relativeLeft;
        data.top = relativeTop;
        let opId = $flowchart.flowchart("addOperator", data);
        $j("#assayInfo").modal("show");
        // console.log(r);
        // console.log($j('#chart_canvas').flowchart('getData'));

        $flowchart.flowchart("selectOperator", opId);
        $j("#operator_properties").hide();
      }
    },
  });
};

const loadFlowchart = () => {
  // $j("#sourceSampleTypeTable").css("visibility", "hidden");
  $j("#source_characteristics_panel").addClass("disabled");
  $j("#source_table_panel").removeClass("disabled");

  const $flowchart = $j("#chart_canvas");
  const { id, type } = selectedItem;
  if (type != "study") {
    console.error("Selected item is not a study");
    return;
  }
  let params = {};
  params.onSuccess = (s) => {
    $j("#flowchart-header").show();
    $flowchart.flowchart("setData", s.data || "");
    existingAssays = $j.map(s.data.operators, (op, i) => {
      if (op.properties.shape_id != "")
        return {
          id: op.properties.shape_id,
          sopTitle: op.properties.title,
        };
    });
    console.log("existingAssays", existingAssays);
  };
  params.onError = (e) => hideFlowchart();
  params.dataType = "json";
  ajaxCall(`/projects/${pid}/flowchart/${id}`, "GET", params);
};

const hideFlowchart = () => {
  // $j("#sourceSampleTypeTable").css("visibility", "visible");
  $j("#source_characteristics_panel").removeClass("disabled");
  $j("#source_table_panel").addClass("disabled");
  $j("#flowchart-header").hide();
  window.location.href = "#study-details";
};

const findFirstBox = (data) => {
  const res = $j.map(data.operators, (op, i) => {
    if (op.properties.shape === "parallelogram") {
      return i;
    }
  });
  return res.length > 0 ? res[0] : undefined;
};

const arrangeBoxes = (OpList, firstBoxId, links) => {
  let arranged = [],
    current = firstBoxId;
  arranged.push(OpList[current]);
  for (let i = 0; i < Object.keys(links).length; i++) {
    $j.each(links, (key, link) => {
      if (link.fromOperator == current) {
        arranged.push(OpList[link.toOperator]);
        current = link.toOperator;
        return false;
      }
    });
  }
  return arranged;
};

const getOperatorName = (operatorId, data) => {
  let opName = "";
  $j.each(data.operators, (op_key, op_val) => {
    if (op_key == operatorId) opName = op_val.properties.title;
  });
  return opName;
};

function setInputNum() {
  let num = $j(this).val();
  if (num >= 0 && num < 4) $j(".wf_btn").data("nb-inputs", num);
}

function setOutputNum() {
  let num = $j(this).val();
  if (num >= 0 && num < 4) $j(".wf_btn").data("nb-outputs", num);
}

const refreshFlowchart = () => {
  setTimeout(() => {
    $j("#chart_canvas").flowchart("redrawLinksLayer");
  }, 250);
};

const validateFlowchart = (data) => {
  // Check for name duplication
  let operatorLength = Object.keys(data.operators).length;
  if (operatorLength == 0) return true;
  if (operatorLength - Object.keys(data.links).length != 1) {
    alert("The items must be connected.");
    return false;
  }
  // // Always 2 baxes with only 1 link
  // let ioBoxes = 0,
  //     connections = 0
  // $j.each(data.operators, (op_key, op_val) => {
  //     $j.each(data.links, (link_key, link_val) => {
  //         if (link_val.toOperator == op_key ||
  //             link_val.fromOperator == op_key)
  //             connections++
  //     })
  //     if (connections == 1) {
  //         ioBoxes++;
  //     }
  //     connections = 0

  // })
  // if (ioBoxes != 2) {
  //     alert("Boxes are not connected correctly!")
  //     return false;
  // }
  // let TableopIndexes = [];
  // $j.map(data.operators, (operator, index) => {
  //     // if (operator.properties.shape === "parallelogram") {
  //     TableopIndexes.push(index);
  //     // }
  // })

  let first = findFirstBox(data); //TableopIndexes, data.links)
  if (data.operators[first].properties.shape != "parallelogram") {
    alert("First item must be a source sample!");
    return false;
  }
  let names = [];
  let nameIsValid = true;
  $j.each(data.operators, (op_key, op_val) => {
    names.push(op_val.properties.title);
  });
  $j.each(names, (id, val) => {
    $j.each(names, (i, v) => {
      if (i != id && val == v) {
        alert("Duplicate names detected!");
        nameIsValid = false;
        return false;
      }
    });
    if (!nameIsValid) return false;
  });
  return nameIsValid ? true : false;
};

function saveAssay() {
  if (!$j("#modalMethodfile")[0].files[0]) {
    e.stopPropagation();
    alert("Please select method file");
    return;
  } else if (!$j("#assayTitle").val()) {
    e.stopPropagation();
    alert("Please enter assay title.");
    return;
  } else if (!$j("#modalMethodTitle").val()) {
    e.stopPropagation();
    alert("Please enter method title.");
    return;
  }
  var Id = $j("#chart_canvas").flowchart("getSelectedOperatorId");
  AssayDetails.push({
    opId: Id,
    title: $j.trim($j("#assayTitle").val()),
    description: $j.trim($j("#assayDes").val()),
    method: {
      type: $j("#method_type").val() || 0,
      file: $j("#modalMethodfile")[0].files[0],
      title: $j("#modalMethodTitle").val(),
      description: $j("#modalMethodDes").val(),
    },
    sampleTypeAttrId: $j("#assayType").children("option:selected").val(),
  });
  console.log(AssayDetails);
  //Add the method detail:
  $j("#chart_canvas").flowchart("setOperatorTitle", Id, $j("#modalMethodTitle").val());
  $j("#assayInfo").hide();
}

function cancelAssay() {
  $j("#assayInfo").hide();
  removeBlock();
}

const removeBlock = () => {
  $j("#chart_canvas").flowchart("deleteSelected");
};

const addAssayTypeOptions = () => {
  $j("#assayType").empty();
  $j.each(AssayTypes, (key, value) => {
    $j("#assayType").append($j("<option></option>").attr("value", key).text(value.title));
  });
  if (AssayTypes[0])
    $j.each(AssayTypes[0].attributes, (k, attr) => {
      const newRow = attr.required
        ? "<td><input disabled checked type='checkbox'/></td>"
        : "<td><input type='checkbox'/></td>";
      let title = attr.required ? "<strong>" + attr.title + "*" + "</strong>" : attr.title;
      $j("#assayAttribs tbody").append(
        `<tr>${newRow}<td>${title}</td><td>${attr.shortName}</td><td>${attr.des}</td></tr>`
      );
    });
};

const asyTypeChange = (i) => {
  // $j("#attribs").empty()
  $j("#assayAttribs tbody").empty();
  $j("#method_type").val(i.value);
  $j("#assayTitle").val(AssayTypes[i.value].title);
  $j.each(AssayTypes[i.value].attributes, (k, attr) => {
    const newRow = attr.required
      ? "<td><input disabled checked type='checkbox'/></td>"
      : "<td><input type='checkbox'/></td>";
    let title = attr.required ? "<strong>" + attr.title + "*" + "</strong>" : attr.title;
    $j("#assayAttribs tbody").append(
      `<tr>${newRow}<td>${title}</td><td>${attr.shortName}</td><td>${attr.des}</td></tr>`
    );
  });
};

function extractAssays(data) {
  return $j.map(data.operators, (op, i) => {
    if (op.properties.shape === "rectangle") {
      return {
        id: op.properties.shape_id,
        opId: i, // for using to identify Assay name associated with the method
      };
    }
  });
}

function getAssayDetail(opId) {
  for (let i = 0; i < AssayDetails.length; i++) {
    if (AssayDetails[i].opId == opId) {
      return AssayDetails[i];
    }
  }
}

function createAssay(pid, std_id, uid, title, desc, sopId, position) {
  const data = createAssayStruct(title, desc, position, pid, std_id, sopId, uid);

  let params = {};
  params.onSuccess = (s) => console.log("assay was created successfully! : " + s.data.id);
  params.onError = (e) => alert("An error occurred when creating assay");
  params.data = JSON.stringify(data);
  params._return = true;
  return ajaxCall("/assays", "POST", params);
}

const createSOP = (title, desc, pid, uid, file) => {
  const data = createSOPStruct(title, desc, file.name, file.type, pid, uid);

  let params = {};
  params.onSuccess = (s) => console.log(`SOP was created successfully!: ${s.data.id}`);
  params.onError = (e) => alert("An error occurred when creating SOP");
  params.data = JSON.stringify(data);
  params._return = true;
  return ajaxCall("/sops", "POST", params);
};

const updateFlowchart = (flowchartData) => {
  const data = {
    flowchart: {
      study_id: selectedItem.id,
      // source_sample_type_id: "??", No need to update!
      // assay_sample_type: [{assay_id:"12", sample_type_id:"1"},{...}],
      items: JSON.stringify(getOrderedSOPs(flowchartData)),
    },
  };
  // console.log(data)
  let params = {};
  params.onSuccess = (s) => location.reload(true);
  params.onError = (e) => console.error("error updating Flowchart!");
  params.data = JSON.stringify(data);
  params.dataType = "json";
  ajaxCall(`/projects/${pid}/update_flowchart`, "POST", params);
};

function saveFlowchart() {
  $j(event.target).attr("disabled", true);
  if (selectedItem.type != "study") return;
  let flowchartData = $j("#chart_canvas").flowchart("getData");
  if (validateFlowchart(flowchartData) == false) return;
  let newAssays = extractAssays(flowchartData);
  if (arrEqualItems(newAssays, existingAssays)) {
    console.log("Equal...");
    updateFlowchart(flowchartData);
    return;
  }

  $j.each(newAssays, (i, assay) => {
    //TO-DO: use ES2015 for async ajax calls
    const tempArr = $j.map(existingAssays, (a) => a.id);
    if ($j.inArray(assay.id, tempArr) == -1) {
      const { title, description, method, sampleTypeAttrId } = getAssayDetail(assay.opId);
      $j.when(createSOP(method.title, method.description, pid, uid, method.file)).then((res) => {
        $j.when(createAssay(pid, selectedItem.id, uid, title, description, res.data.id, i)).then((res) => {
          updateIds(flowchartData, res.data.id, method.title);
          const attr = AssayTypes[sampleTypeAttrId].attributes;
          const data = sampleTypeData(attr, `sample_type_${res.data.id}`, res.data.id);
          $j.when(createSampleType(data, () => {})).then((res) => {
            if (i == newAssays.length - 1) {
              updateFlowchart(flowchartData);
            }
          });
        });
      });
    }
  });
}

const updateIds = (data, id, title) => {
  $j.each(data.operators, (i, op) => {
    if (title == op.properties.title) {
      op.properties.shape_id = id;
    }
  });
};

const arrEqualItems = (arr1, arr2) => {
  arr1 = $j.map(arr1, (item) => item.id);
  arr2 = $j.map(arr2, (item) => item.id);
  for (let i = 0; i < arr1.length; i++) {
    if ($j.inArray(arr1[i], arr2) == -1) return false;
  }
  return true;
};

const getOrderedSOPs = (data) => {
  let arranged = [],
    current = 0;
  arranged.push(data.operators[current]);
  for (let i = 0; i < Object.keys(data.links).length; i++) {
    $j.each(data.links, (key, link) => {
      if (link.fromOperator == current) {
        arranged.push(data.operators[link.toOperator]);
        current = link.toOperator;
        return false;
      }
    });
  }

  console.log("arranged", arranged);

  return $j.map(arranged, (op, i) => ({
    id: arranged[i].properties.shape_id,
    left: arranged[i].left,
    top: arranged[i].top,
  }));
};
