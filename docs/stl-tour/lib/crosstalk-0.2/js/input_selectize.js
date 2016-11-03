"use strict";

var _input = require("./input");

var input = _interopRequireWildcard(_input);

var _util = require("./util");

var util = _interopRequireWildcard(_util);

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

var $ = global.jQuery;

input.register({
  className: "crosstalk-input-select",

  factory: function factory(el, data) {
    /*
     * items: {value: [...], label: [...]}
     * map: {"groupA": ["keyA", "keyB", ...], ...}
     * group: "ct-groupname"
     */

    var first = [{ value: "", label: "(All)" }];
    var items = util.dataframeToD3(data.items);
    var opts = {
      options: first.concat(items),
      valueField: "value",
      labelField: "label"
    };

    var select = $(el).find("select")[0];

    var selectize = $(select).selectize(opts)[0].selectize;

    var ctGroup = global.crosstalk.group(data.group);
    var ctHandle = global.crosstalk.filter.createHandle(ctGroup);

    selectize.on("change", function () {
      if (selectize.items.length === 0) {
        ctHandle.clear();
      } else {
        (function () {
          var keys = {};
          selectize.items.forEach(function (group) {
            data.map[group].forEach(function (key) {
              keys[key] = true;
            });
          });
          var keyArray = Object.keys(keys);
          keyArray.sort();
          ctHandle.set(keyArray);
        })();
      }
    });

    return selectize;
  }
});
//# sourceMappingURL=input_selectize.js.map
