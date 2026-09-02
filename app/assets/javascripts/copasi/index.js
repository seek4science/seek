// Page-scoped bundle for the COPASI simulation page.
// Not part of application.js: copasijs is ~9.4MB (WASM inlined as base64) and
// is only needed by models/copasi_simulate. Must stay registered in
// config/initializers/assets.rb precompile list.
//= require copasi/copasi
//= require copasi/copasijs
//= require copasi/copasi_simulation
//= require plotly-2.27.0.min
