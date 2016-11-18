"use strict";

var _input = require("./input");

var input = _interopRequireWildcard(_input);

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

var $ = global.jQuery;

input.register({
  className: "crosstalk-input-colour-picker",

  factory: function factory(el, data) {
    // initiate the colourpicker
    var $el = $(el).find("input")[0];
    $el.colourpicker(data.settings);
    // set the starting value
    $el.colourpicker("value", data.value);

    $el.on("change", function () {
      var ctGroup = global.crosstalk.group(data.group);
      ctGroup.var("colourPalette").set($el.colourpicker("value"));
    });

    return $el;
  }
});
//# sourceMappingURL=input_colour_picker.js.map
