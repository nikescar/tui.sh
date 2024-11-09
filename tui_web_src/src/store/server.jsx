import { createStore } from "solid-js/store";
import { createSignal, createEffect } from "solid-js";

const [status, setStatus] = createSignal(0);

export { status, setStatus };
