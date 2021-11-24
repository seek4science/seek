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
  if (!item) return;
  let index = ["project", "investigation", "study", "assay"].indexOf(item);
  $j(`.bcrumb li:nth-child(${index + 1}) a`).addClass("active");
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

const batchSampleCreateStruct = (ex_id, attribute_map, sample_type_id, pid) => ({
  ex_id,
  data: {
    type: "samples",
    attributes: {
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
      }
    }
  }
});

async function setAutoComplete(e, sample_controlled_vocab_id) {
  try {
    const setSource = (data) => {
      $j(e).autocomplete({
        classes: {
          "ui-autocomplete": "highlight"
        },
        source: data || [],
        mustMatch: true
      });
    };

    let url = "/single_pages/" + pid + "/ontology?sample_controlled_vocab_id=";
    url += sample_controlled_vocab_id + "&query=" + $j(e).html();
    const res = await ajaxCall(url, "GET", { dataType: "json" });

    if (res.status == "ok") {
      setSource(res.data);
      $j(e).autocomplete("search", "a");
    }
  } catch (err) {
    console.log(err);
  }
}

async function batchCreateSample(sampleTypes) {
  try {
    let data = [];
    sampleTypes.forEach((s) => {
      s.samples.forEach((sa, k) => {
        data.push(batchSampleCreateStruct(sa.exId, sa.data, s.sampleTypeId, s.pid));
      });
    });

    if (data.length == 0) {
      console.log("No samples to create");
      return;
    }
    console.log(data);
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
    console.log(data);
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
      console.log("No samples to create");
      return;
    }
    console.log(data);
    return ajaxCall("/samples/batch_update/", "PUT", { data: JSON.stringify({ data }) });
  } catch (e) {
    console.log(e);
  }
}
