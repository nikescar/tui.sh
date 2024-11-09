import { A } from "@solidjs/router";
import { createSignal } from "solid-js";
import { TextField } from "@kobalte/core/text-field";
import "./overview.css";
import LogViewer from "~/components/LogViewer";

// let div = document.getElementById("target");
//         div.onload = function() {
//             div.style.height =
//             div.contentWindow.document.body.scrollHeight + 'px';
//         }

function History() {
  return (
    <>
      <h2>Config History</h2>
      configuration managed by bkit is monitored with aide. configuration will
      be automatically committed on following conditions.
      <br />
      * there are changes in configuration files uncommitted.
      <br />
      * all enabled service process is normal.
      <br />
      * cpu usage is less than 10%. # of active config files loaded.
      <br />
      <div>
        <iframe
          src="/etc_stagit"
          width="100%"
          height="400px"
          onload={(e) => {
            var height =
              eval(e.currentTarget.contentWindow.document.body.scrollHeight) +
              50;
            e.currentTarget.style.height = height.toString() + "px";
          }}
        />
        -automatically generated with stagit.
      </div>
    </>
  );
}

export default History;
