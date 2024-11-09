import { A } from "@solidjs/router";
import { createSignal } from "solid-js";
import { TextField } from "@kobalte/core/text-field";
import "./overview.css";
import LogViewer from "~/components/LogViewer";


function Overview() {

  return (
    <> 
        <h2>System Information : </h2>
        <LogViewer readpath="/proc/system" boxlabel="-Autogenerated by neofetch" />

        <h2>System Benchmark : </h2>
        <LogViewer readpath="/proc/benchmark" boxlabel="-Autogenerated by shellbench" />
    </>
  );
}

export default Overview;