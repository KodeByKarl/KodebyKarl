import { createOptions } from "./createOptions.js";

const optionsWrapper = document.getElementById("options-wrapper");
const body = document.body;
const eye = document.getElementById("eyeSvg");
const targetContainer = document.getElementById("target-container");
const optionsCount = document.getElementById("options-count");

window.addEventListener("message", (event) => {
  switch (event.data.event) {
    case "visible": {
      optionsWrapper.innerHTML = "";
      if (targetContainer) targetContainer.style.display = "none";
      body.style.visibility = event.data.state ? "visible" : "hidden";
      return eye.classList.remove("eye-hover");
    }

    case "leftTarget": {
      optionsWrapper.innerHTML = "";
      if (targetContainer) targetContainer.style.display = "none";
      return eye.classList.remove("eye-hover");
    }

    case "setTarget": {
      optionsWrapper.innerHTML = "";
      eye.classList.add("eye-hover");

      let totalOptions = 0;

      if (event.data.options) {
        for (const type in event.data.options) {
          event.data.options[type].forEach((data, id) => {
            if (!data.hide) {
              createOptions(type, data, id + 1);
              totalOptions++;
            }
          });
        }
      }

      if (event.data.zones) {
        for (let i = 0; i < event.data.zones.length; i++) {
          event.data.zones[i].forEach((data, id) => {
            if (!data.hide) {
              createOptions("zones", data, id + 1, i + 1);
              totalOptions++;
            }
          });
        }
      }

      if (targetContainer) {
        if (totalOptions > 0) {
          if (optionsCount) optionsCount.textContent = totalOptions;
          targetContainer.style.display = "flex";
        } else {
          targetContainer.style.display = "none";
        }
      }
    }
  }
});
