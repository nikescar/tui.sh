import {
  createSignal,
  For,
  onMount,
  onCleanup,
  createComputed,
  mergeProps,
} from "solid-js";
import { createStore, reconcile } from "solid-js/store";
import {
  createDropzone,
  createFileUploader,
  fileUploader,
} from "@solid-primitives/upload";

export const doStuff = (s) => {
  return new Promise((res) => setTimeout(res, s * 1000));
};

export default function CSVSelect() {
  const { files, selectFiles } = createFileUploader();
  const { files: filesAsync, selectFiles: selectFilesAsync } =
    createFileUploader();
  const [text, setText] = createSignal("");

  return (
    <div>
      <div>
        <h5>Please Select Log File : </h5>
        <button
          onClick={() => {
            selectFilesAsync(async ([{ source, name, size, file }]) => {
              //   await doStuff(2);
              //   setText("bcd");
              //   var fileReader = new FileReader();
              //   fileReader.onload = function (e) {
              //     var text = e.target.result;
              //     //   setText(text);
              //   };
              //   fileReader.readAsText(file);
              //   // console.log("a", file);
            });
          }}>
          Select
        </button>
        <For each={filesAsync()}>
          {(file) => {
            var fileReader = new FileReader();
            fileReader.onload = function (e) {
              var text = e.target.result;
              setText([text]);
              console.log(text);
              console.log(text);
            };
            fileReader.readAsText(file["file"]);
            console.log(file["file"]);
          }}
        </For>
        <div>{text}</div>
      </div>
    </div>
  );
}
