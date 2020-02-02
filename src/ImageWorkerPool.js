import { Queue } from "./Queue";
import { ImageWorker } from "./ImageWorker";

export class ImageWorkerPool {
  constructor(capacity = 10) {
    /**
     * @type {ImageWorker[]}
     */
    this.availableInstances = [];
    this.waitQueue = new Queue();

    for (let i = 0; i < capacity; i++) {
      this.availableInstances.push(new ImageWorker());
    }
  }

  exec(data) {
    return new Promise((resolve, reject) => {
      this.waitQueue.enqueue({ data, resolve, reject });
      this._work();
    });
  }

  _work() {
    const worker = this.availableInstances.pop();
    if (!worker) return;

    const task = this.waitQueue.dequeue();
    if (!task) return this.availableInstances.push(worker);

    const { data, resolve, reject } = task;

    worker
      .exec(data)
      .then(result => {
        this.availableInstances.push(worker);
        setTimeout(() => this._work());
        return result;
      })
      .then(resolve)
      .catch(reject);
  }
}
