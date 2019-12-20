import JSZip from "jszip";

onmessage = function(e) {
  const values = e.data;
  const zip = new JSZip();
  values.forEach((value, index) => zip.file(`file_${index}.jpeg`, value));
  zip.generateAsync({ type: "blob" }).then(content => postMessage(content));
};
