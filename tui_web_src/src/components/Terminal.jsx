import { Show, createSignal, createEffect, onMount, onCleanup } from "solid-js";
// Using ES6 import syntax
import hljs from "highlight.js/lib/core";
// hljs.initHighlighting.called = false;
import "highlight.js/styles/atom-one-dark.css";

// console.log("initialie");
import javascript from "highlight.js/lib/languages/javascript";
import accesslog from "highlight.js/lib/languages/accesslog";

// Then register the languages you need
hljs.registerLanguage("accesslog", accesslog);

export default function Terminal(props) {
  const highlightedCode = hljs.highlightAuto(props.content).value;
  hljs.debugMode();

  // console.log("highlighting");
  // const highlightedCode = hljs.highlightAuto(props.content).value;
  // hljs.highlightAll();
  // const highlightedCode = hljs.highlight(props.content, {
  //   language: "accesslog",
  // }).value;

  return (
    <main>
      <div class="codebox">
        <pre class="theme-atom-one-dark shadow-3xl text-sm relative overflow-hidden max-w-full tab-size h-full">
          <span class="hljs mb-0 p-4 block min-h-full overflow-auto">
            <code innerHTML={highlightedCode}></code>
          </span>
          {/* <small class="bg-black/30 absolute top-0 right-0 uppercase font-bold text-xs rounded-bl-md px-2 py-1">
            <span class="sr-only">Language:</span>Apache Access Log
          </small> */}
        </pre>
      </div>
    </main>
  );
}
