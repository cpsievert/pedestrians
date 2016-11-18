"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _group = require("./group");

var _group2 = _interopRequireDefault(_group);

var _selection = require("./selection");

var selection = _interopRequireWildcard(_selection);

var _filter = require("./filter");

var filter = _interopRequireWildcard(_filter);

require("./input");

require("./input_selectize");

require("./input_checkboxgroup");

require("./input_slider");

require("./input_colour_picker");

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var defaultGroup = (0, _group2.default)("default");

function var_(name) {
  return defaultGroup.var(name);
}

function has(name) {
  return defaultGroup.has(name);
}

if (global.Shiny) {
  global.Shiny.addCustomMessageHandler("update-client-value", function (message) {
    if (typeof message.group === "string") {
      (0, _group2.default)(message.group).var(message.name).set(message.value);
    } else {
      var_(message.name).set(message.value);
    }
  });
}

var crosstalk = {
  group: _group2.default,
  var: var_,
  has: has,
  selection: selection,
  filter: filter
};

exports.default = crosstalk;

global.crosstalk = crosstalk;
//# sourceMappingURL=index.js.map
