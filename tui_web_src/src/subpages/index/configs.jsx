import { createSignal } from "solid-js";
import { Accordion } from "@kobalte/core/accordion";
import PsEditor from "~/components/PsEditor";
import "./configs.css";
//import { css } from 'solid-styled';

function Configs() {
  var files = [
    { id: 1, path: "/etc/bkit.conf", origSha256: "" },
    { id: 2, path: "/etc/aide/aide.conf", origSha256: "" },
    { id: 3, path: "/etc/dnscrypt-proxy/dnscrypt-proxy.toml", origSha256: "" },
  ];
  const [color, setColor] = createSignal("red");
  return (
    <div class="configs">
      <h2>Configs</h2>

      <Accordion class="accordion" defaultValue={["item-1"]}>
        <For each={files} fallback={<p>Loading...</p>}>
          {(file) => (
            <Accordion.Item class="accordion__item" value={"item-" + file.id}>
              <Accordion.Header class="accordion__item-header">
                <Accordion.Trigger class="accordion__item-trigger">
                  {file.path}
                </Accordion.Trigger>
              </Accordion.Header>
              <Accordion.Content class="accordion__item-content">
                {/* <LogEditor readpath={file()} boxlabel={file()} /> */}
                <PsEditor readpath={file.path} boxlabel={file.path} />
              </Accordion.Content>
            </Accordion.Item>
          )}
        </For>
      </Accordion>
    </div>
  );
}

export default Configs;
