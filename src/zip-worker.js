import JSZip from "jszip";

onmessage = function(e) {
  const images = e.data;
  const zip = new JSZip();
  images.forEach((image, index) =>
    zip.file(`${image.name || index}.jpeg`, image.blob)
  );
  zip.generateAsync({ type: "blob" }).then(content => postMessage(content));
};
