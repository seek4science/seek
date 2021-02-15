const ajaxCall = (url, method, params) => {
  const { data, onSuccess, onComplete, onError, cache, dataType, _return, _headers } = params;
  let headers = null;
  if (_headers != "hide")
    headers = {
      "Content-Type": "application/json",
      Accept: "application/json",
    };

  if (!url || !method) {
    throw new Error("Parameter(s) missing");
  }
  const _ajax = () =>
    $j.ajax({
      method,
      url,
      data,
      dataType,
      cache: cache || false,
      headers,
      success: (s) => {
        if (onSuccess) onSuccess(s);
      },
      complete: (jqXHR, textStatus) => {
        if (onComplete) onComplete(jqXHR, textStatus);
      },
      error: (e) => {
        if (onError) onError(e);
      },
    });
  if (_return) return _ajax();
  else _ajax();
};

const createSampleStruct = (attribute_map, sample_type_id, project_id) => {
  return {
    data: {
      type: "samples",
      attributes: {
        title: "sample",
        attribute_map,
        tags: null,
      },
      relationships: {
        sample_type: {
          data: {
            id: sample_type_id,
            type: "sample_types",
          },
        },
        projects: {
          data: [
            {
              id: project_id,
              type: "projects",
            },
          ],
        },
      },
    },
  };
};

const updateSampleStruct = (attribute_map) => {
  return {
    data: {
      type: "samples",
      attributes: {
        attribute_map,
      },
    },
  };
};

const updateSampleTypeStruct = (attribute_map) => {
  return {
    data: {
      type: "sample_types",
      attributes: {
        attribute_map,
      },
    },
  };
};

const createInvestigationStruct = (title, description, pid, uid) => {
  return {
    data: {
      type: "investigations",
      attributes: {
        title,
        policy: {
          access: "download",
          permissions: [
            {
              resource: {
                id: pid,
                type: "projects",
              },
              access: "manage",
            },
          ],
        },
        description,
      },
      relationships: {
        projects: {
          data: [
            {
              id: pid,
              type: "projects",
            },
          ],
        },
        publications: {
          data: [],
        },
        creators: {
          data: [
            {
              id: uid,
              type: "people",
            },
          ],
        },
      },
    },
  };
};

const createStudyStruct = (title, description, pid, invId, uid) => {
  return {
    data: {
      type: "studies",
      attributes: {
        title,
        description,
        policy: {
          access: "download",
          permissions: [
            {
              resource: {
                id: pid,
                type: "projects",
              },
              access: "manage",
            },
          ],
        },
      },
      relationships: {
        investigation: {
          data: {
            id: invId,
            type: "investigations",
          },
        },
        publications: {
          data: [],
        },
        creators: {
          data: [
            {
              id: uid,
              type: "people",
            },
          ],
        },
      },
    },
  };
};

const createSOPStruct = (title, description, fileName, fileType, pid, uid) => {
  return {
    data: {
      type: "sops",
      attributes: {
        title,
        description,
        content_blobs: [
          {
            original_filename: fileName,
            content_type: fileType,
          },
        ],
        policy: {
          access: "download",
          permissions: [
            {
              resource: {
                id: pid,
                type: "projects",
              },
              access: "manage",
            },
          ],
        },
      },
      relationships: {
        projects: {
          data: [
            {
              id: pid,
              type: "projects",
            },
          ],
        },
        creators: {
          data: [
            {
              id: uid,
              type: "people",
            },
          ],
        },
      },
    },
  };
};

const createAssayStruct = (title, description, position, pid, std_id, sopId, uid) => {
  return {
    data: {
      type: "assays",
      attributes: {
        title,
        description,
        position,
        assay_class: {
          key: "EXP",
        },
        policy: {
          access: "download",
          permissions: [
            {
              resource: {
                id: pid,
                type: "projects",
              },
              access: "manage",
            },
          ],
        },
      },
      relationships: {
        study: {
          data: {
            id: std_id,
            type: "studies",
          },
        },
        sops: {
          data: [
            {
              id: sopId,
              type: "sops",
            },
          ],
        },
        creators: {
          data: [
            {
              id: uid,
              type: "people",
            },
          ],
        },
      },
    },
  };
};

const updateSOP = (methodId, title, description) => {
  return {
    data: {
      type: "sops",
      id: methodId,
      attributes: {
        title,
        description,
      },
    },
  };
};

const createSampleTypeStruct = (title, description, attribute_map, pid, assayId) => {
  return {
    data: {
      type: "sample_types",
      attributes: {
        title,
        description,
        attribute_map,
        tags: null,
      },
      relationships: {
        projects: {
          data: [
            {
              id: pid,
              type: "projects",
            },
          ],
        },
        assays: {
          data: [
            {
              id: assayId,
              type: "assays",
            },
          ],
        },
      },
    },
  };
};

//**Visibility Manager */
const VM = (item, field) => {
  if (item) item = item.toString();
  const std_id = selectedItem.parent.id;
  const key = `${uid}_${pid}_${std_id}_dynamicTableHidden${field}`;
  if (!localStorage[key]) localStorage[key] = JSON.stringify([]);
  let header = JSON.parse(localStorage[key]);

  return {
    hide: () => {
      if (!header.includes(item)) header.push(item);
      localStorage[key] = JSON.stringify(header);
    },
    unhide: () => {
      header = $j.grep(header, (k) => k != item);
      localStorage[key] = JSON.stringify(header);
    },
    get: () => JSON.parse(localStorage[key]),
    toggle: () => {
      if (!header.includes(item)) header.push(item);
      else header = $j.grep(header, (k) => k != item);
      localStorage[key] = JSON.stringify(header);
    },
    clear: () => localStorage.clear(),
  };
};

function breadcrumb(item) {
  $j(".bcrumb li").hide();
  switch (item) {
    case "project":
      $j(".bcrumb li:first-child").show();
      break;
    case "investigation":
      $j(".bcrumb li:first-child, li:nth-child(2)").show();
      break;
    case "study":
      $j(".bcrumb li:first-child, li:nth-child(2), li:nth-child(3)").show();
      break;
    case "assay":
      $j(".bcrumb li:first-child, li:nth-child(2), li:nth-child(3), li:nth-child(4)").show();
      break;
  }
}

function deleteSOP(id, cb) {
  $j.ajax({
    method: "DELETE",
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
    },
    cache: false,
    url: `/sops/${id}`,
    success: (s) => cb(),
    error: (e) =>
      e.responseJSON.errors
        ? alert(e.responseJSON.errors[0].title + "\n" + e.responseJSON.errors[0].details)
        : alert("Cannot process the request"),
  });
}

function deleteAssay(id, t) {
  if (confirm("Are you sure you want to delete the assay and all items associated with it?")) {
    const cb = (id) => {
      let params = {};
      params.onSuccess = (s) => location.reload(true);
      params.onComplete = () => $j(t).attr("disabled", true);
      params.onError = (e) => {
        console.error(e);
        $j(t).attr("disabled", false);
        if (e.responseJSON.errors)
          alert(e.responseJSON.errors[0].title + "\n" + e.responseJSON.errors[0].details);
        else alert("Cannot process the request");
      };
      ajaxCall(`/assays/${id}`, "DELETE", params);
    };
    // TO-DO: Add a method to the API that deletes all assets of the assay
    // For now, if the assay has assets other than SOP, the situation will be a bit of mess!
    deleteSOP($j("#method-id").val(), () => cb(id));
  }
}

const addInvestigations = (t) => {
  $j("#data-file-modal-inv").modal({
    backdrop: "static",
    keyboard: true,
  });
};

const addStudies = (t) => {
  //Change the JStree active item to the associated Investigation id
  selectedItem.id = $j(t).parent().children(".jstree-anchor").attr("_id");
  selectedItem.type = "investigation";
  $j("#data-file-modal-std").modal({
    backdrop: "static",
    keyboard: true,
  });
};

const deleteItem = (t) => {
  event.preventDefault();
  let { id, type } = selectedItem;
  if (type == "assay") {
    deleteAssay(id, t);
    return;
  }
  if (!id || !type) {
    alert("Please select item.");
    return;
  }
  if (confirm("Are you sure you want to delete the " + type + "?")) {
    $j(t).attr("disabled", true);
    if (type == "study") type = "studies";
    else type += "s";

    let params = {};
    params.onSuccess = (s) => location.reload(true);
    params.onComplete = () => $j(t).attr("disabled", false);
    params.onError = (e) => {
      console.error(e);
      $j(t).attr("disabled", false);
      if (e.responseJSON.errors) {
        let msg = e.responseJSON.errors[0].title;
        msg += "\n" + e.responseJSON.errors[0].details;
        msg += "\n" + "There maybe some items associated with this item.";
        alert(msg);
      } else alert("Cannot process the request");
    };
    ajaxCall(`/${type}/${id}`, "DELETE", params);
  }
};

function submitInvestigation() {
  if ($j("#investigation_title").val().length == 0) {
    alert("Please enter a title.");
    return;
  }
  $j(event.target).attr("disabled", "disabled");
  const data = createInvestigationStruct(
    $j("#investigation_title").val(),
    $j("#investigation_description").val(),
    pid,
    uid
  );
  let params = {};
  params.onSuccess = (s) => location.reload(true);
  params.onError = (e) => console.log("error creating investigation!");
  params.data = JSON.stringify(data);
  ajaxCall("/investigations", "POST", params);
}

function submitStudy() {
  if ($j("#study_title").val().length == 0) {
    alert("Please enter a title.");
    return;
  }
  $j(event.target).attr("disabled", "disabled");
  const data = createStudyStruct(
    $j("#study_title").val(),
    $j("#study_description").val(),
    pid,
    selectedItem.id,
    uid
  );
  let params = {};
  params.onSuccess = (s) => location.reload(true);
  params.onError = (e) => console.log("error creating study!");
  params.data = JSON.stringify(data);
  ajaxCall("/studies", "POST", params);
}

function updateInvSharing() {
  $j(event.target).attr("disabled", "disabled");
  const form = $j("#investigation-sharing-form");
  const url = `/investigations/${selectedItem.id}/manage_update`;
  let params = {};
  params.onSuccess = (s) => alert("Sharing permissions updated!");
  params.onError = (e) => alert("Can not perform the operation.");
  params.onComplete = () => $j("#inv_update_btn").removeAttr("disabled");
  params.data = form.serialize();
  params._headers = "hide";
  ajaxCall(url, "POST", params);
}
function updateStudySharing() {
  $j(event.target).attr("disabled", "disabled");
  const form = $j("#study-sharing-form");
  const url = `/studies/${selectedItem.id}/manage_update`;
  let params = {};
  params.onSuccess = (s) => alert("Sharing permissions updated!");
  params.onError = (e) => alert("Can not perform the operation.");
  params.onComplete = () => $j("#std_update_btn").removeAttr("disabled");
  params.data = form.serialize();
  params._headers = "hide";
  ajaxCall(url, "POST", params);
}

function updateMethod() {
  $j(event.target).attr("disabled", "disabled");
  const methodId = $j("#method-id").val();
  const data = updateSOP(methodId, $j("#method-title").val(), $j("#method_description").val());
  let params = {};
  params.onSuccess = (s) => {
    $j(this).removeAttr("disabled");
    location.reload();
  };
  params.onError = (e) => {
    $j(this).removeAttr("disabled");
    alert("An error occurred when updating the method");
  };
  params.onComplete = () => $j("#std_update_btn").removeAttr("disabled");
  params.data = JSON.stringify(data);
  ajaxCall(`/sops/${methodId}`, "PATCH", params);
}
