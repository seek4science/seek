// app/assets/javascripts/copasi_simulation.js

var copasi = null;

function automaticChanged() {
    var autoStepSize = document.getElementById("autoStepSize").checked;
    document.getElementById("numPoints").disabled = autoStepSize;
}

function loadIntoCOPASI() {
    var info = copasi.loadModel(document.getElementById("cps").value);
    document.getElementById("model_name").innerHTML = "none";
    if (info['status'] != "success") {
        document.getElementById("simulation_error").innerHTML = "Error loading model: " + info['messages'];
        document.getElementById('simulation_error').hidden = false;
    }
    document.getElementById("model_name").innerHTML = 'Model name: ' + info['model']['name'];
    document.getElementById("copasi_version").innerHTML = 'Copasi version: ' + copasi.version;
    document.getElementById('simulation_info').hidden = false;
}

function simulate() {
    if (copasi == null) {
        alert('There is a problem to load Copasi simulator.');
        return;
    }
    loadIntoCOPASI();
    runSimulation();
}

function runSimulation() {
    var autoStepSize = document.getElementById("autoStepSize").checked;
    var timeStart = parseFloat(document.getElementById("startTime").value);
    var timeEnd = parseFloat(document.getElementById("endTime").value);

    if (autoStepSize) {
        var result = copasi.simulateYaml({
            "problem": {
                "AutomaticStepSize": true,
                "Duration": timeEnd,
                "OutputStartTime": timeStart
            }
        });
        loadPlotFromResult(result);
        return;
    }

    var numPoints = parseInt(document.getElementById("numPoints").value);
    var result = copasi.simulateEx(timeStart, timeEnd, numPoints);
    loadPlotFromResult(result);
}

function loadPlotFromResult(result) {
    if (typeof result === 'string') {
        result = JSON.parse(result);
    }

    clearResults();
    document.getElementById("data").innerHTML = JSON.stringify(result);

    var data = [];
    for (var i = 1; i < result.num_variables; i++) {
        data.push({
            name: result.columns[i][0],
            x: result.columns[0],
            y: result.columns[i],
            type: "scatter",
            name: result.titles[i]
        });
    }

    Plotly.newPlot('chart', data);
}

function clearResults() {
    document.getElementById("data").innerHTML = "";
    document.getElementById("chart").innerHTML = "";
}

