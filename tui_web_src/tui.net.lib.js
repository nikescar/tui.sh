import { createStore, unwrap, reconcile } from "solid-js/store";
import {
  createSignal,
  createMemo,
  createEffect,
  onMount,
  For,
  Show,
  createResource,
  createReaction,
} from "solid-js";
import {
  tuiTree,
  setTuiTree,
  selectedMenu,
  setSelectedMenu,
  tuiConfig,
  setTuiConfig,
  parseConfig,
} from "./src/store/yaml";
import { btoa, atob } from "Base64";
import YAML from "yaml";

const [tuiReq, setTuiReq] = createStore({ reqId: 0 });
// step: 0 before request -> send request /dummy/tnet/1/1/data <-> fail [4]
// step: 1 sent reqeust, -> get request result /var/net/REQ00001 EOP && 200 -> remove /var/net/REQ00001 <-> error/fail [4]
// step: 2 get response, -> get response result /var/net/RES00001 EOP && 200 -> remove /var/net/RES00001 <-> error/fail [4]
// step: 3 finished
// step: 4 error/fail
const reqMap = new Map();
class TuiRequest {
  address = "/";
  reqId = 0;
  step = 0;
  stepRepeated = 0;
  sqncTotal = 0;
  sqnc = new Map();
  responseUpdated = 0;
  response = "";

  checkFillSqnc() {
    return this.sqnc.size == this.sqncTotal;
  }

  // reqSqnc.set("a", 1);
  // reqSqnc.set("a", 97);
  // console.log(reqSqnc.get("a"));
  // reqSqnc.delete("b");
  // console.log(reqSqnc.size);
}
// const req = new TuiRequest();
// req.speak(); // the Animal object
// const speak = req.speak;
// speak(); // undefined

const getLastReqId = () => {
  var keys = reqMap.keys().sort();
  console.log(keys);
};

// req generator
const fwdrequest = async (reqid, data) => {
  // getting reqobj from map
  var c = unwrap(tuiConfig).config;
  var reqObj = new TuiRequest();
  reqObj.address = data.address;
  if (reqMap.has(reqid)) {
    reqObj = reqMap.get(reqid);
  } else {
    reqObj.reqId = reqid;
    reqObj.responseUpdated = 0;
    reqMap.set(reqid, reqObj);
  }
  if (reqObj.step == 0 && reqObj.sqncTotal > 0) {
    reqObj.step = 1;
    reqObj.stepRepeated = 0;
  }
  // step0 send request
  if (reqObj.step == 0) {
    // step0 parse data
    var strline = "";
    if (typeof data == "object" && Array.isArray(data) == false) {
      strline = YAML.stringify(data);
    }
    if (strline.length < 1) return reqObj;
    strline = btoa(strline);
    // step0 split to chunk
    var strarr = [];
    if (strline.length > 1000) {
      const chunkSize = 1000;
      for (let i = 0; i < strline.length; i += chunkSize) {
        strarr.push(strline.slice(i, i + chunkSize));
      }
    } else {
      strarr.push(strline);
    }
    reqObj.sqncTotal = strarr.length;
    // step0 send chunk
    for (let i = 0; i < strarr.length; i++) {
      var eor = "";
      var response = "";
      if (i + 1 == strarr.length) {
        eor = "__EOR__";
      }

      if (c.transfer_field == "useragent") {
        // Authorization: "Basic dGVzdDp0ZXN0",
        response = await fetch("/dummy", {
          cache: "no-store",
          redirect: "manual",
          headers: {
            "Content-Type": "text/html; charset=utf-8",
            Authorization: "Basic " + btoa(c.tui_basic_auth),
            "User-Agent":
              " /dummy/tnet/" + reqid + "/" + i + "/" + strarr[i] + eor,
          },
        })
          .then((e) => console.log("error", e))
          .then((r) => {
            if (r.ok) {
              // succesful transfer, error or not
              reqObj.sqnc.set(i, 1);
            }
          });
      }
      if (c.transfer_field == "url") {
        response = await fetch(
          "/dummy/tnet/" + reqid + "/" + i + "/" + strarr[i] + eor,
          {
            cache: "no-store",
            redirect: "manual",
            headers: {
              "Content-Type": "text/html; charset=utf-8",
              Authorization: "Basic " + btoa(c.tui_basic_auth),
            },
          }
        ).then((e) => {
          // console.log(e);
          if (e.ok == false) {
            // succesful transfer, error or not
            reqObj.sqnc.set(i, 1);
          }
        });
      }
    }
    reqObj.stepRepeated++;
    if (reqObj.sqncTotal > 0) {
      reqObj.step = 1;
      reqObj.stepRepeated = 0;
    }
    // if (response.indexOf("E0503" > 0)) {
    //   reqObj.step = 4;
    //   reqObj.stepRepeated = 0;
    // }
    if (reqObj.stepRepeated > 5) {
      reqObj.step = 4;
      reqObj.stepRepeated = 0;
    }
  }
  // step1 check request received
  if (reqObj.step == 1) {
    var response = "";
    if (reqObj.checkFillSqnc()) {
      reqObj.step = 1;
      // check if request received /var/net/REQ00001
      response = await fetch("/var/net/REQ" + ("00000" + reqid).slice(-5), {
        headers: {
          "Content-Type": "text/html; charset=utf-8",
          Authorization: "Basic " + btoa(c.tui_basic_auth),
        },
      }).then((r) => r.text());
      reqObj.stepRepeated++;
      if (response.substr(-4, 3) == "EOP") {
        reqObj.step = 2;
        reqObj.stepRepeated = 0;
      }
      // if (response.indexOf("E0503" > 0)) {
      //   reqObj.step = 4;
      //   reqObj.stepRepeated = 0;
      // }
      if (reqObj.stepRepeated > 5) {
        reqObj.step = 4;
        reqObj.stepRepeated = 0;
      }
    }
  }
  // step2 check response has finished
  if (reqObj.step == 2) {
    var response = "";
    response = await fetch("/var/net/RES" + ("00000" + reqid).slice(-5), {
      headers: {
        "Content-Type": "text/html; charset=utf-8",
        Authorization: "Basic " + btoa(c.tui_basic_auth),
      },
    }).then((r) => r.text());
    reqObj.stepRepeated++;
    // console.log(reqObj.response != response);
    if (reqObj.response != response) {
      reqObj.responseUpdated = 1;
      reqObj.response = response;
    } else {
      reqObj.responseUpdated = 0;
    }

    if (response.indexOf("> FIN") > 0) {
      reqObj.step = 3;
      reqObj.stepRepeated = 0;
    }
    // if (response.indexOf("E0503" > 0)) {
    //   reqObj.step = 4;
    //   reqObj.stepRepeated = 0;
    // }
    if (reqObj.stepRepeated > 5) {
      reqObj.step = 4;
      reqObj.stepRepeated = 0;
    }
  }
  // step3 all step done.
  if (reqObj.step == 3) {
    // finished
  }
  // step4 some error.
  if (reqObj.step == 4) {
    // error
  }
  return reqObj;
};

export { tuiReq, setTuiReq, fwdrequest, getLastReqId };
