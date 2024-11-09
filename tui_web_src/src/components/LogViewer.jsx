import { TextField } from "@kobalte/core/text-field";
import { createSignal, createMemo, createEffect, onMount, For } from "solid-js";
import "./LogViewer.css";

function LogViewer(props) {
  // console.log(props);
  const [logtext, setLogtext] = createSignal("loading...", {
    equals: (oldVal, newVal) => newVal.length === oldVal.length,
  });
  // createEffect(() => console.log("count =", logtext));
  onMount(async () => {
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
    setLogtext(await text.text());
  });

  return (
    <>
      <div data-editor="html">
        <pre class="numbers"></pre>
        <textarea
          class="textarea"
          spellcheck="false"
          autocorrect="off"
          autocapitalize="off"
          disabled
          style="height: auto"
        >
          {logtext}
        </textarea>
      </div>
      {/* <TextField>
            <TextField.TextArea autoResize={false} readOnly={true}>
              {logtext}
            </TextField.TextArea>
            <TextField.Label>{props.boxlabel}</TextField.Label>
        </TextField> */}
    </>
  );
}

export default LogViewer;
