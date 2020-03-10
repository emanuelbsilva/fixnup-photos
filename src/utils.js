export function dataURItoBlob(dataURI) {
  // convert base64 to raw binary data held in a string
  // doesn't handle URLEncoded DataURIs - see SO answer #6850276 for code that does this
  var byteString = atob(dataURI.split(",")[1]);

  // separate out the mime component
  var mimeString = dataURI
    .split(",")[0]
    .split(":")[1]
    .split(";")[0];

  // write the bytes of the string to an ArrayBuffer
  var ab = new ArrayBuffer(byteString.length);

  // create a view into the buffer
  var ia = new Uint8Array(ab);

  // set the bytes of the buffer to the correct values
  for (var i = 0; i < byteString.length; i++) {
    ia[i] = byteString.charCodeAt(i);
  }

  // write the ArrayBuffer to a blob, and you're done
  var blob = new Blob([ab], { type: mimeString });
  return blob;
}

export function saveAs(blob, filename) {
  var elem = window.document.createElement("a");
  elem.href = window.URL.createObjectURL(blob);
  elem.download = filename;
  elem.style.cssText = "display:none;opacity:0;color:transparent;";
  (document.body || document.documentElement).appendChild(elem);
  if (typeof elem.click === "function") {
    elem.click();
  } else {
    elem.target = "_blank";
    elem.dispatchEvent(
      new MouseEvent("click", {
        view: window,
        bubbles: true,
        cancelable: true
      })
    );
  }
  URL.revokeObjectURL(elem.href);
}

export function getAngledImage({ src, angle }) {
  return new Promise((resolve, reject) => {
    createImageBitmap(dataURItoBlob(src)).then(img => {
      try {
        angle = (angle * Math.PI) / 180;

        var { width, height } = getAngledImageSize(
          angle,
          img.width,
          img.height
        );

        const canvas = new OffscreenCanvas(width, height);
        var ctx = canvas.getContext("2d");

        ctx.save();
        ctx.translate(0, img.height / 2);
        ctx.rotate(-angle);
        ctx.translate(-(img.height * Math.sin(angle)) / 2, img.height / 2);
        ctx.drawImage(img, 0, 0);
        ctx.restore();
        canvas
          .convertToBlob({
            type: "image/png",
            quality: 0.95
          })
          .then(blob => resolve(blob));
      } catch (e) {
        reject(e);
      }
    });
  });
}

export function applyPatternToCanvas({ canvas, blob }) {
  return new Promise((resolve, reject) => {
    createImageBitmap(blob).then(img => {
      var ctx = canvas.getContext("2d");
      var pattern = ctx.createPattern(img, "repeat");
      ctx.fillStyle = pattern;
      ctx.globalAlpha = 0.05;
      ctx.fillRect(0, 0, canvas.width, canvas.height);
      resolve();
    });
  });
}

export const applyWatermark = ({ canvas, src }) => {
  return getAngledImage({ src, angle: 20 }).then(blob => {
    return applyPatternToCanvas({ canvas, blob });
  });
};

function getAngledImageSize(a, x0, y0) {
  return {
    width: x0 * Math.cos(a) + y0 * Math.sin(a),
    height: x0 * Math.sin(a) + y0 * Math.cos(a)
  };
}
