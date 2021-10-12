const ajaxCall = (url, method, params) => {
  const { data, onSuccess, onComplete, onError, cache, dataType, _return, _headers } = params;
  let headers = null;
  if (_headers != "hide")
    headers = {
      "Content-Type": "application/json",
      Accept: "application/json"
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
      }
    });
  if (_return) return _ajax();
  else _ajax();
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
                type: "projects"
              },
              access: "manage"
            }
          ]
        },
        description
      },
      relationships: {
        projects: {
          data: [
            {
              id: pid,
              type: "projects"
            }
          ]
        },
        publications: {
          data: []
        },
        creators: {
          data: [
            {
              id: uid,
              type: "people"
            }
          ]
        }
      }
    }
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
                type: "projects"
              },
              access: "manage"
            }
          ]
        }
      },
      relationships: {
        investigation: {
          data: {
            id: invId,
            type: "investigations"
          }
        },
        publications: {
          data: []
        },
        creators: {
          data: [
            {
              id: uid,
              type: "people"
            }
          ]
        }
      }
    }
  };
};

function updateBreadcrumb(item) {
  $j(".bcrumb li a").removeClass("active");
  if (!item) return;
  let index = ["project", "investigation", "study", "assay"].indexOf(item);
  $j(`.bcrumb li:nth-child(${index + 1}) a`).addClass("active");
}

const addInvestigations = (t) => {
  $j("#data-file-modal-inv").modal({
    backdrop: "static",
    keyboard: true
  });
};

const addStudies = (t) => {
  //Change the JStree active item to the associated Investigation id
  selectedItem.id = $j(t).parent().children(".jstree-anchor").attr("_id");
  selectedItem.type = "investigation";
  $j("#data-file-modal-std").modal({
    backdrop: "static",
    keyboard: true
  });
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

let timer;
function debounce(func, timeout = 300) {
  return (...args) => {
    clearTimeout(timer);
    timer = setTimeout(() => {
      func.apply(this, args);
    }, timeout);
  };
}
