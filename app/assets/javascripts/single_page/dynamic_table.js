const rowStatus = { new: "new", delete: "delete", update: "update", empty: "empty", noAction: "" };
const dtErrClass = "row-error",
  dtSuccessClass = "row-success",
  dtDeletedClass = "disabled",
  dtRowDelete = "row-delete";
const defaultCols = [
  {
    width: "10px",
    className: "text-center",
    mRender: function (data, type, full) {
      return "<td><input class='row-select' type='checkbox' onClick='handleCheck($j(this))'/></td>";
    }
  }
];

const objectInput =
  "<td><input data-role='seek-objectsinput' data-tags-limit='3' " +
  "data-existing-objects='%EXISTING%' data-typeahead='true' " +
  "data-typeahead-query-url=%URL% /></td>";
const typeaheadUrl = "/samples/typeahead?query=%QUERY&linked_sample_type_id=%LINKED%";

const handleCheck = (e) => (e.parents("table").DataTable().row(e.closest("tr")).data()[0] = e.is(":checked"));

(function ($j) {
  $j.dynamicTable = function (table) {
    this.table = table instanceof $j ? table : $j(table);
  };
  $j.dynamicTable.prototype = {
    init: function (rows, columns, options = {}) {
      columns
        .filter((c) => c.multi_link)
        .forEach((c) => {
          c["mRender"] = function (data, type, full) {
            const existingObjectsJSON = (data || []).map(({ id, title }) => ({ id: id, name: title }));
            const existingObjects = JSON.stringify(existingObjectsJSON);
            const url = typeaheadUrl.replace("%LINKED%", c.linked_sample_type);
            if (options.readonly) {
              return existingObjectsJSON.map((e) => `<span class="badge">${e.name}</span>`).join(" ");
            } else {
              return objectInput.replace("%EXISTING%", existingObjects).replace("%URL%", url);
            }
          };
          c["createdCell"] = function (td, cellData, rowData, row, col) {
            setTagsInput($j(td));
          };
        });
      columns.unshift(...defaultCols);
      const columnDefs = [
        { orderable: false, targets: options.readonly ? [0] : [0, 1, 2] },
        {
          targets: [1, 2],
          visible: false,
          searchable: false
        }
      ];
      const editor = this.editor;
      this.table = this.table.DataTable({
        columnDefs,
        columns,
        scrollX: "100%",
        errMode: "throw",
        order: [[options.readonly ? 1 : 3, "asc"]],
        pageLength: 25,
        dom:
          "<'row'<'col-sm-3'l><'col-sm-5'B><'col-sm-4'f>>" +
          "<'row'<'col-sm-12'tr>>" +
          "<'row'<'col-sm-5'i><'col-sm-7'p>>",
        buttons: "main"
      });
      this.table.rows.add(rows.map((r) => [null, ...r])).draw();
      if (!options.readonly) {
        const table = this.table;
        const context = this;
        this.table.on("click", "tbody td:not(:has(input))", function () {
          editor($j(this), table, context);
        });
      }
      if (options.assayId) this.assayId = options.assayId;
    },
    pasteFromClipboard: function () {
      navigator.clipboard.readText().then((text) => {
        const colsCount = this.table.columns().data().length;
        const splitter = text.includes("\r\n") ? "\r\n" : "\n";
        const delimeter = "\t";
        const rows = text.split(splitter).map((r) => {
          let splitted = [rowStatus.new, ""].concat(r.split(delimeter));
          const missingColsCount = colsCount - defaultCols.length - splitted.length;
          splitted = defaultCols.map((c) => c.defaultValue || "").concat(splitted);
          return missingColsCount < 0
            ? splitted.slice(0, colsCount)
            : splitted.concat(Array(missingColsCount).fill(""));
        });
        this.table.rows.add(rows).draw();
      });
    },
    newRow: function () {
      const colsCount = this.table.columns().data().length;
      const arr = defaultCols
        .map((c) => c.defaultValue || "")
        .concat(Array(colsCount - defaultCols.length).fill(""));
      const cols = this.table.settings()[0].aoColumns;
      const indexes = getStatusIndexes(cols);
      const sampleLinkIndexes = getSampleLinkingIndexes(cols);
      indexes.forEach((x) => (arr[x] = rowStatus.new));
      sampleLinkIndexes.forEach((x) => (arr[x] = []));
      this.table.row.add(arr).draw();
    },
    setAsDeleted: function () {
      const indexes = getStatusIndexes(this.table.settings()[0].aoColumns);
      this.table.rows(function (idx, data, node) {
        if (data[0]) {
          indexes.forEach((x) => {
            // empty status is a placeholder for missing samples
            // Check if the sample has an ID (data[x+1]) (it's an existing sample)
            if (data[x + 1]) data[x] = rowStatus.delete;
          });
          $j(node).addClass(dtRowDelete);
        }
      });
    },
    save: async function () {
      this.resetClasses();
      //=======================DELETE==================================
      const deletedSamples = this.getSamples(rowStatus.delete);
      //* Delete action is applied to all samples in a row
      let res = await batchDeleteSample(deletedSamples);
      if (res) handleResponse(this.table, deletedSamples, dtErrClass, dtDeletedClass)(res);
      //=======================UPDATE==================================
      const updatedSamples = this.getSamples(rowStatus.update);
      res = await batchUpdateSample(updatedSamples);
      if (res) handleResponse(this.table, updatedSamples, dtErrClass, dtSuccessClass)(res);
      //=======================CREATE==================================
      const sampleTypeIds = this.getSampleTypes();
      for (const s of sampleTypeIds) {
        const newSamples = this.getSamples(rowStatus.new, s);
        res = await batchCreateSample(newSamples);
        if (res) {
          handleResponse(this.table, newSamples, dtErrClass, dtSuccessClass)(res);
        }
      }
    },
    headers: function () {
      return this.table
        .columns()
        .header()
        .toArray()
        .map((x) => x.innerText)
        .slice(defaultCols.length);
    },
    getSampleTypes: function () {
      return this.table
        .settings()[0]
        .aoColumns.map((c) => c.name)
        .filter((value, index, self) => value && self.indexOf(value) === index);
    },
    getSamples: function (status, sampleTypeId = null) {
      const rowsIdx = this.table.rows().indexes().toArray();
      const sampleTypeIds = sampleTypeId ? [sampleTypeId] : this.getSampleTypes();
      return sampleTypeIds.map((s) => {
        const columnNames = this.table
          .settings()[0]
          .aoColumns.filter((c) => c.name === s)
          .map((c) => c.title);
        return {
          pid: pid.toString(),
          sampleTypeId: s,
          assayId: this.assayId,
          // Returning those samples that apply the 'status'
          samples: rowsIdx.reduce((filtered, i) => {
            const item = this.table.cells(i, `${s}:name`).data().toArray();
            if (item[0] == status)
              filtered.push({
                id: item[1],
                exId: `${i}-${s}`,
                data: item.reduce((obj, curr, j) => ({ ...obj, [columnNames[j]]: checkSampleLink(curr) }), {})
              });
            return filtered;
          }, [])
        };
      });
    },
    log: function () {
      console.log(this.table.rows().data());
    },
    getCvId: function (colIndex) {
      return this.table.settings()[0].aoColumns[colIndex].cv_id;
    },
    editor: function (elem, table, context) {
      elem
        .attr("contenteditable", true)
        .focus()
        .unbind()
        .blur(function () {
          table.cell(elem).data(elem.text());
          elem.attr("contenteditable", false);
          table.columns.adjust();
          handleCellUpdate(table, elem);
        });

      const colIndex = table.cell(elem).index().column;
      const cvId = context.getCvId(colIndex);
      if (cvId) setAutoComplete(elem, cvId);
    },
    resetClasses: function () {
      $j(`#${this.table.tables().nodes().to$().attr("id")} td`).removeClass(dtErrClass);
    },
    toggleSampleType: function (sampleTypeId, visible) {
      this.table.columns(`${sampleTypeId}:name`).visible(visible);
    }
  };
})(jQuery);

function checkSampleLink(value) {
  if (Array.isArray(value)) {
    return value.map((x) => x.id).join(",");
  } else return value;
}

function sampleStatus(table, rowId, sampleTypeId, value = null) {
  const sampleStatusIndex = table
    .settings()[0]
    .aoColumns.findIndex((x) => x?.status && x.name == sampleTypeId);
  if (value) table.row(rowId).data()[sampleStatusIndex] = value;
  else return table.row(rowId).data()[sampleStatusIndex];
}

function getStatusIndexes(arr) {
  return arr.filter((x) => x?.status).map((x) => x.idx);
}

function getSampleLinkingIndexes(arr) {
  return arr.filter((x) => x.linked_sample_type).map((x) => x.idx);
}

function setTagsInput(item) {
  // There's a new input after the table is rendered
  const newInput = item.find("input").first();
  loadObjectInputs({ item: newInput });
  newInput.on("itemAdded itemRemoved", function (event) {
    const items = $j(this).tagsinput("items");
    const values = items.map(({ id, name }) => ({
      id,
      title: name
    }));
    const table = $j(this).parents("table").DataTable();
    const elem = $j(this).parent();
    const td = $j(this).closest("td");
    table.cell(elem).data(values);
    handleCellUpdate(table, elem);
    setTagsInput($j(td));
    table.columns.adjust();
  });
}

function handleCellUpdate(table, cell) {
  const { row, column } = table.cell(cell).index();
  const colName = table.settings()[0].aoColumns[column].name;
  // sampleType status col index
  const sampleStatusIndex = table.settings()[0].aoColumns.findIndex((x) => x?.status && x.name == colName);
  // If it is a new sample, then it has to be created
  const status = table.row(row).data()[sampleStatusIndex];
  if (status == rowStatus.empty) {
    table.row(row).data()[sampleStatusIndex] = rowStatus.new;
  } else if (status == "") {
    table.row(row).data()[sampleStatusIndex] = rowStatus.update;
  }
}

function handleResponse(table, sampleTypes, errorCls, successCls) {
  return function (res) {
    if (res.status == "unprocessable_entity") {
      res.errors.forEach((error) => {
        const [rowId, sampleTypeId] = error.ex_id.split("-");
        const errorColNames = Object.keys(error.error);
        table.cells(rowId, `${sampleTypeId}:name`).every(function () {
          const idx = this.index().column;
          const colTitle = $j(table.column(idx).header()).html();
          if (errorColNames.includes(colTitle)) {
            $j(this.node()).addClass(errorCls);
            $j(this.node()).attr("title", error.error[colTitle]);
          }
        });
      });
      alert("The operation can not be done for one or some samples.");
    } else if (res.status == "ok") {
      sampleTypes.forEach((s) => {
        s.samples.forEach((sa, k) => {
          const [rowId, sampleTypeId] = sa.exId.split("-");
          table.cells(rowId, `${sampleTypeId}:name`).every(function (rowIdx, columnIdx) {
            sampleStatus(table, rowId, sampleTypeId, rowStatus.noAction);
            $j(this.node()).addClass(successCls);
          });
        });
      });
    }
  };
}
