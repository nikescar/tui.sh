import { Show, createSignal, createEffect, onMount, onCleanup } from "solid-js";
import "./PsEditor.css";

// https://stackoverflow.com/a/77832699 https://stackoverflow.com/a/77832699
const updateLineNumbers = (elEditor) => {
  const elNumbers = elEditor.querySelector(".numbers");
  const elTextarea = elEditor.querySelector(".textarea");
  const scrollHeight = elTextarea.offsetHeight;
  const lineHeight = parseFloat(getComputedStyle(elTextarea).lineHeight);
  const totLines = Math.floor(scrollHeight / lineHeight);
  elNumbers.innerHTML = "<span></span>".repeat(totLines);
};

const tabToSpaces = (evt) => {
  if (evt.key !== "Tab") return;
  evt.preventDefault(); // this will prevent us from tabbing out of the editor

  const spaces = " ".repeat(4);
  // document.execCommand("insertHTML", false, spaces);
};

const updateTextareaHeight = (elTextarea) => {
  elTextarea.style.height = 0;
  elTextarea.style.height = elTextarea.scrollHeight + "px";
};

const makeEditor = (elEditor, content) => {
  const elTextarea = elEditor.querySelector(".textarea");

  elTextarea.addEventListener("keydown", (evt) => {
    tabToSpaces(evt);
  });

  elTextarea.addEventListener("input", (evt) => {
    updateTextareaHeight(elTextarea);
    updateLineNumbers(elEditor);
  });

  addEventListener(
    "resize",
    () => {
      updateTextareaHeight(elTextarea);
      updateLineNumbers(elEditor);
    },
    true
  );

  updateTextareaHeight(elTextarea);
  updateLineNumbers(elEditor);
};

export default function PsEditor(props) {
  const [container, setContainer] = createSignal();
  const [menu, setMenu] = createSignal();
  const [editor, setEditor] = createSignal();
  const regExp = /[^a-z]/g;
  const pathid =
    props.readpath.toLowerCase().replace(regExp, "") || "textaredid";

  onMount(async () => {
    console.log("create", props.readpath, pathid);
    const text = await fetch(props.readpath, {
      headers: {
        "Content-Type": "text/html; charset=utf-8",
        Authorization: "Basic dGVzdDp0ZXN0",
      },
    }); //.then(function (response) {
    //   console.log(response);
    //   return response.text();
    // }).then(function (data) {
    //   console.log(data);
    // }).catch(function (err) {
    //   console.warn('Something went wrong.', err);
    // });
    var content = await text.text();
    document.getElementById(pathid).innerHTML = content;
    console.log("pass here 77", content);

    document.querySelectorAll("[data-editor]").forEach(makeEditor);
  });
  onMount(() => {
    // Init for multiple .editor elements!
    console.log("pass here 81");
    //document.querySelectorAll("[data-editor]").forEach(makeEditor);
  });
  onCleanup(() => {
    console.log("remove", props.readpath, pathid);
  });
  return (
    <div data-editor="html">
      <pre class="numbers"></pre>
      <textarea
        id={pathid}
        class="textarea"
        spellcheck="false"
        autocorrect="off"
        autocapitalize="off"
      ></textarea>
    </div>
  );
}

// todo : textarea prismjs highlight https://live.prismjs.com/
// https://jsfiddle.net/wales/2azkLnad/
