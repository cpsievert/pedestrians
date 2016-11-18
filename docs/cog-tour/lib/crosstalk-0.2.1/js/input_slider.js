"use strict";

var _slicedToArray = function () { function sliceIterator(arr, i) { var _arr = []; var _n = true; var _d = false; var _e = undefined; try { for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"]) _i["return"](); } finally { if (_d) throw _e; } } return _arr; } return function (arr, i) { if (Array.isArray(arr)) { return arr; } else if (Symbol.iterator in Object(arr)) { return sliceIterator(arr, i); } else { throw new TypeError("Invalid attempt to destructure non-iterable instance"); } }; }();

var _input = require("./input");

var input = _interopRequireWildcard(_input);

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

var $ = global.jQuery;
var strftime = global.strftime;

input.register({
  className: "crosstalk-input-slider",

  factory: function factory(el, data) {
    /*
     * map: {"groupA": ["keyA", "keyB", ...], ...}
     * group: "ct-groupname"
     */
    var ctGroup = global.crosstalk.group(data.group);
    var ctHandle = global.crosstalk.filter.createHandle(ctGroup);

    var opts = {};
    var $el = $(el).find("input");
    var dataType = $el.data("data-type");
    var timeFormat = $el.data("time-format");
    var timeFormatter;

    // Set up formatting functions
    if (dataType === "date") {
      timeFormatter = strftime.utc();
      opts.prettify = function (num) {
        return timeFormatter(timeFormat, new Date(num));
      };
    } else if (dataType === "datetime") {
      var timezone = $el.data("timezone");
      if (timezone) timeFormatter = strftime.timezone(timezone);else timeFormatter = strftime;

      opts.prettify = function (num) {
        return timeFormatter(timeFormat, new Date(num));
      };
    }

    $el.ionRangeSlider(opts);

    function getValue() {
      var result = $el.data("ionRangeSlider").result;

      // Function for converting numeric value from slider to appropriate type.
      var convert = void 0;
      var dataType = $el.data("data-type");
      if (dataType === "date") {
        convert = function convert(val) {
          return formatDateUTC(new Date(+val));
        };
      } else if (dataType === "datetime") {
        convert = function convert(val) {
          // Convert ms to s
          return +val / 1000;
        };
      } else {
        convert = function convert(val) {
          return +val;
        };
      }

      if ($el.data("ionRangeSlider").options.type === "double") {
        return [convert(result.from), convert(result.to)];
      } else {
        return convert(result.from);
      }
    }

    $el.on("change.crosstalkSliderInput", function (event) {
      if (!$el.data("updating") && !$el.data("animating")) {
        var _getValue = getValue();

        var _getValue2 = _slicedToArray(_getValue, 2);

        var from = _getValue2[0];
        var to = _getValue2[1];

        var keys = [];
        for (var i = 0; i < data.values.length; i++) {
          var val = data.values[i];
          if (val >= from && val <= to) {
            keys.push(data.keys[i]);
          }
        }
        keys.sort();
        ctHandle.set(keys);
      }
    });

    // let $el = $(el);
    // $el.on("change", "input[type="checkbox"]", function() {
    //   let checked = $el.find("input[type="checkbox"]:checked");
    //   if (checked.length === 0) {
    //     ctHandle.clear();
    //   } else {
    //     let keys = {};
    //     checked.each(function() {
    //       data.map[this.value].forEach(function(key) {
    //         keys[key] = true;
    //       });
    //     });
    //     let keyArray = Object.keys(keys);
    //     keyArray.sort();
    //     ctHandle.set(keyArray);
    //   }
    // });
  }
});

// Convert a number to a string with leading zeros
function padZeros(n, digits) {
  var str = n.toString();
  while (str.length < digits) {
    str = "0" + str;
  }return str;
}

// Given a Date object, return a string in yyyy-mm-dd format, using the
// UTC date. This may be a day off from the date in the local time zone.
function formatDateUTC(date) {
  if (date instanceof Date) {
    return date.getUTCFullYear() + "-" + padZeros(date.getUTCMonth() + 1, 2) + "-" + padZeros(date.getUTCDate(), 2);
  } else {
    return null;
  }
}
//# sourceMappingURL=input_slider.js.map
