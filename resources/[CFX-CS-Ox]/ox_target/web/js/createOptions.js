import { fetchNui } from "./fetchNui.js";

const optionsWrapper = document.getElementById("options-wrapper");

function onClick() {
  this.style.pointerEvents = "none";
  fetchNui("select", [this.targetType, this.targetId, this.zoneId]);
  setTimeout(() => (this.style.pointerEvents = "auto"), 100);
}

export function createOptions(type, data, id, zoneId) {
  if (data.hide) return;

  const option = document.createElement("div");
  option.className = "option-container";
  option.targetType = type;
  option.targetId = id;
  option.zoneId = zoneId;

  const numberBadge = document.createElement("div");
  numberBadge.className = "option-number-badge";
  numberBadge.textContent = id;

  const iconBox = document.createElement("div");
  iconBox.className = "option-icon-box";

  const icon = document.createElement("i");
  icon.className = `fa-fw ${data.icon} option-icon`;
  if (data.iconColor) {
    icon.style.color = data.iconColor;
  }
  iconBox.appendChild(icon);

  const label = document.createElement("p");
  label.className = "option-label";
  label.textContent = data.label;

  option.appendChild(numberBadge);
  option.appendChild(iconBox);
  option.appendChild(label);

  option.addEventListener("click", onClick);
  optionsWrapper.appendChild(option);
}
