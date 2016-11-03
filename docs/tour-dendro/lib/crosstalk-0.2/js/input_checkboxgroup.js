"use strict";

var _input = require("./input");

var input = _interopRequireWildcard(_input);

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

var $ = global.jQuery;

input.register({
  className: "crosstalk-input-checkboxgroup",

  factory: function factory(el, data) {
    /*
     * map: {"groupA": ["keyA", "keyB", ...], ...}
     * group: "ct-groupname"
     */
    var ctGroup = global.crosstalk.group(data.group);
    var ctHandle = global.crosstalk.filter.createHandle(ctGroup);

    var $el = $(el);
    $el.on("change", "input[type='checkbox']", function () {
      var checked = $el.find("input[type='checkbox']:checked");
      if (checked.length === 0) {
        ctHandle.clear();
      } else {
        (function () {
          var keys = {};
          checked.each(function () {
            data.map[this.value].forEach(function (key) {
              keys[key] = true;
            });
          });
          var keyArray = Object.keys(keys);
          keyArray.sort();
          ctHandle.set(keyArray);
        })();
      }
    });
  }
});
//# sourceMappingURL=input_checkboxgroup.js.map
