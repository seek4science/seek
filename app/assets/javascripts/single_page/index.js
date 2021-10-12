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
