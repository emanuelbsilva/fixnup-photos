"use strict";
import {} from "./styles.scss";
import ZipWorker from "worker-loader!./zip-worker.js";
import { Elm } from "./Main";
import { saveAs } from "./utils.js";
import { ImageWorkerPool } from "./ImageWorkerPool";

var app = Elm.Main.init();

let state = 0;
let total = 0;
app.ports.generateImages.subscribe(({ images, watermark }) => {
  state = 0;
  total = images.length;
  Promise.all(images.map(image => processImage({ watermark, image }))).then(
    images => {
      createZip(images).then(content => {
        app.ports.receiveZip.send(1);
        saveAs(content, "photos.zip");
      });
    }
  );
});

function createZip(images) {
  return new Promise(resolve => {
    const worker = new ZipWorker();
    worker.postMessage(images);
    worker.onmessage = function(e) {
      resolve(e.data);
      worker.terminate();
    };
  });
}

const imagePool = new ImageWorkerPool(5);

function processImage({ image, watermark }) {
  return new Promise(resolve => {
    imagePool.exec({ image, watermark }).then(data => {
      data
        .arrayBuffer()
        .then(blob => resolve(Object.assign({}, data, { blob })));
      state++;
      app.ports.imageProgress.send((state / total) * 100);
    });
  });
}
