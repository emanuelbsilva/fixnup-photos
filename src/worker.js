import { dataURItoBlob, applyWatermark } from "./utils";

onmessage = function(e) {
  const { image, watermark } = e.data;
  createImageBitmap(dataURItoBlob(image.src)).then(img => {
    const canvas = new OffscreenCanvas(img.width, img.height);
    const ctx = canvas.getContext("2d");
    ctx.filter = `saturate(${image.saturation}%) contrast(${image.contrast}%) brightness(${image.brightness}%) `;
    ctx.drawImage(img, 0, 0);

    applyWatermark({ canvas, src: watermark }).then(() => {
      canvas
        .convertToBlob({
          type: "image/jpeg",
          quality: 0.95
        })
        .then(blob => {
          postMessage(blob);
        });
    });
  });
};
