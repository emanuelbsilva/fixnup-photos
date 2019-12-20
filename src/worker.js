const { dataURItoBlob } = require("./utils");

onmessage = function(e) {
  createImageBitmap(dataURItoBlob(e.data.src)).then(img => {
    const canvas = new OffscreenCanvas(img.width, img.height);
    const ctx = canvas.getContext("2d");
    ctx.filter = `saturate(${e.data.saturation}%) contrast(${
      e.data.contrast
    }%) brightness(${e.data.brightness}%) `;
    ctx.drawImage(img, 0, 0);
    canvas
      .convertToBlob({
        type: "image/jpeg",
        quality: 0.95
      })
      .then(blob => {
        postMessage(blob);
      });
  });
};
