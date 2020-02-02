export class Queue {
  constructor(capacity = 0) {
    this.capacity = capacity;
    this.queue = [];
  }

  enqueue(val) {
    if (this.isFull()) return;
    this.queue.push(val);
  }

  dequeue() {
    return this.queue.shift();
  }

  isFull() {
    return this.capacity > 0 && this.queue.length >= this.capacity;
  }
}
