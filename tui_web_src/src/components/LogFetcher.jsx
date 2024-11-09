import {
  Show,
  createSignal,
  createEffect,
  createResource,
  onMount,
  onCleanup,
} from "solid-js";
import { createStore, unwrap, reconcile } from "solid-js/store";
import hljs from "highlight.js/lib/core";
import "highlight.js/styles/a11y-dark.css";
import { tuiReq, setTuiReq, fwdrequest } from "../../tui.net.lib";
import { status, setStatus } from "../store/server";
import "./LogFetcher.css";

export default function LogFetcher(props) {
  const [content, setContent] = createSignal({ value: "", language: "" });

  const reqId = unwrap(tuiReq).reqId + 1;
  setTuiReq({ reqId: reqId });
  var reqObj = undefined;

  const fetchTuiNet = async () => {
    reqObj = await fwdrequest(reqId, { ...props });
    if (reqObj.step != 2 && reqObj.step != 3) {
      return false;
    }
    if (reqObj.responseUpdated) {
      var hightlighted = hljs.highlightAuto(reqObj.response);
      setContent({
        value: hightlighted.value,
        language: hightlighted.language,
      });
    }
  };

  const [shouldFetch, setShouldFetch] = createSignal();
  const [data, { refetch }] = createResource(shouldFetch, fetchTuiNet);

  onMount(() => {
    setShouldFetch(true);
  });

  const timer = setInterval(() => {
    if (reqObj) {
      if (reqObj.stepRepeated > 10) {
        clearInterval(timer);
      }
      if (reqObj.stepRepeated < 2) {
        refetch();
      }
    }
  }, 800);
  onCleanup(() => clearInterval(timer));

  return (
    <main>
      <div class="codebox">
        <pre class="theme-a11y-dark shadow-3xl text-sm relative overflow-hidden max-w-full tab-size h-full">
          <span class="hljs mb-0 p-4 block min-h-full overflow-auto">
            <code
              innerHTML={content().value}
              class={"language-" + content().language}
            ></code>
          </span>
          {/* <small class="bg-black/30 absolute top-0 right-0 uppercase font-bold text-xs rounded-bl-md px-2 py-1">
            <span class="sr-only">Language:</span>Apache Access Log //
          </small> */}
        </pre>
      </div>
    </main>
  );
}
