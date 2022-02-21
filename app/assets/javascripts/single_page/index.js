const ajaxCall = (url, method, params) => {
  const { data, cache, dataType } = params;
  if (!url || !method) throw new Error("Parameter(s) missing");
  return $j.ajax({
    method,
    url,
    data,
    dataType,
    cache: cache || false,
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json"
    }
  });
};

function updateBreadcrumb(item) {
  $j(".bcrumb li a").removeClass("active");
  if (item) {
    const elements = {
      project: ["project", "folder"],
      investigation: ["investigation"],
      study: ["study", "source_material", "sample_collection", "study_samples", "study_table"],
      assay: ["assay", "sop", "data_file", "document", "sample"]
    };
    item = Object.keys(elements).find((e) => elements[e].includes(item.toLowerCase()));
    let index = ["project", "investigation", "study", "assay"].indexOf(item);
    $j(`.bcrumb li:nth-child(${index + 1}) a`).addClass("active");
  }
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

const batchSampleDeleteStruct = (ex_id, id) => ({
  id,
  ex_id
});

const batchSampleUpdateStruct = (ex_id, attribute_map, id) => ({
  id,
  ex_id,
  data: {
    type: "samples",
    attributes: {
      attribute_map
    }
  }
});

const getAccessType = (code) => {
  switch (code) {
    case 0:
      return "no_access";
    case 1:
      return "view";
    case 2:
      return "download";
    case 3:
      return "edit";
    case 4:
      return "manage";
  }
};

const getAccess = (projectDefaultPolicy) => {
  const t = projectDefaultPolicy?.access_type;
  return t ? getAccessType(t) : 0;
};

const getPermission = (projectDefaultPolicy, pid) => {
  const t = projectDefaultPolicy?.permissions;
  const accessType =
    t && t.find((x) => x.contributor_type == "Project" && x.contributor_id == pid)?.access_type;
  return getAccessType(accessType || 0);
};

const batchSampleCreateStruct = (
  ex_id,
  attribute_map,
  sample_type_id,
  pid,
  projectDefaultPolicy,
  assay_id = null
) => ({
  ex_id,
  data: {
    type: "samples",
    attributes: {
      policy: {
        access: getAccess(projectDefaultPolicy),
        permissions: [
          {
            resource: { type: "Project", id: pid },
            access: getPermission(projectDefaultPolicy, pid)
          }
        ]
      },
      attribute_map
    },
    tags: null,
    relationships: {
      projects: {
        data: [
          {
            id: pid,
            type: "projects"
          }
        ]
      },
      sample_type: {
        data: {
          id: sample_type_id,
          type: "sample_types"
        }
      },
      ...(assay_id && {
        assays: {
          data: [
            {
              id: assay_id,
              type: "assays"
            }
          ]
        }
      })
    }
  }
});

//** =============Autocomplete============== */
async function setAutoComplete(e, cvId) {
  $j(e).on("input", function () {
    fetchTerms($j(e), cvId);
  });
  if ($j(e).autocomplete() && !$j($j(e).autocomplete("widget")).is(":visible")) {
    fetchTerms($j(e), cvId);
  }
}

const setSource = (elem, data) => {
  elem.autocomplete({
    classes: {
      "ui-autocomplete": "highlight"
    },
    source: data,
    minLength: 0,
    mustMatch: true
  });
};

async function fetchTerms(elem, cvId) {
  if (!elem.find(".loader").length) elem.append("<span class='loader'></span>");
  let url = `/single_pages/${pid}/ontology?sample_controlled_vocab_id=${cvId}&query=${elem.text()}`;
  const res = await ajaxCall(url, "GET", { dataType: "json" });
  if (res.status == "ok") {
    setSource(elem, res.data);
    elem.focus().autocomplete("search");
    elem.find(".loader").remove();
  }
}
//** =============End Autocomplete============== */

async function batchCreateSample(sampleTypes, projectDefaultPolicy) {
  try {
    let data = [];
    sampleTypes.forEach((s) => {
      s.samples.forEach((sa, k) => {
        data.push(
          batchSampleCreateStruct(sa.exId, sa.data, s.sampleTypeId, s.pid, projectDefaultPolicy, s.assayId)
        );
      });
    });

    if (data.length == 0) {
      console.log("No samples to create");
      return;
    }
    return ajaxCall("/samples/batch_create/", "POST", { data: JSON.stringify({ data }) });
  } catch (e) {
    console.log(e);
  }
}

async function batchDeleteSample(sampleTypes) {
  try {
    let data = [];
    sampleTypes.forEach((s) => {
      s.samples.forEach((sa, k) => {
        data.push(batchSampleDeleteStruct(sa.exId, sa.id));
      });
    });

    if (data.length == 0) {
      console.log("No samples to delete.");
      return;
    }
    return ajaxCall("/samples/batch_delete/", "DELETE", { data: JSON.stringify({ data }) });
  } catch (e) {
    console.log(e);
  }
}

async function batchUpdateSample(sampleTypes) {
  try {
    let data = [];
    sampleTypes.forEach((s) => {
      s.samples.forEach((sa, k) => {
        data.push(batchSampleUpdateStruct(sa.exId, sa.data, sa.id));
      });
    });

    if (data.length == 0) {
      console.log("No samples to update");
      return;
    }
    return ajaxCall("/samples/batch_update/", "PUT", { data: JSON.stringify({ data }) });
  } catch (e) {
    console.log(e);
  }
}
