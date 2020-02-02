import Worker from "worker-loader!./worker.js";

export class ImageWorker {
  constructor() {
    this.cb = null;
    this.worker = new Worker();
    this.worker.onmessage = event => {
      if (this.cb) this.cb(event.data);
    };
  }

  exec(data) {
    return new Promise((resolve, reject) => {
      if (this.cb) reject();
      this.cb = data => {
        this.cb = null;
        resolve(data);
      };
      this.worker.postMessage(data);
    });
  }
}
