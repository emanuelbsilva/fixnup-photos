"use strict";
require("./styles.scss");

import Worker from "worker-loader!./worker.js";
import ZipWorker from "worker-loader!./zip-worker.js";
import { Elm } from "./Main";
import { saveAs } from "./utils.js";

var app = Elm.Main.init();

let state = 0;
let total = 0;
app.ports.generateImages.subscribe(data => {
  state = 0;
  total = data.length;
  Promise.all(data.map(processImage)).then(values => {
    createZip(values).then(content => {
      app.ports.receiveZip.send(1);
      saveAs(content, "photos.zip");
    });
  });
});

function createZip(files) {
  return new Promise((resolve, reject) => {
    const worker = new ZipWorker();
    worker.postMessage(files);
    worker.onmessage = function(e) {
      resolve(e.data);
      worker.terminate();
    };
  });
}

function processImage(data) {
  return new Promise((resolve, reject) => {
    var worker = new Worker();
    worker.postMessage(data);
    worker.onmessage = function(e, a) {
      e.data.arrayBuffer().then(b => resolve(b));
      state++;
      app.ports.imageProgress.send((state / total) * 100);
      worker.terminate();
    };
  });
}
