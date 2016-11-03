"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.register = register;
var $ = global.jQuery;

var bindings = {};

function register(reg) {
  bindings[reg.className] = reg;
  if (global.document && global.document.readyState !== "complete") {
    $(function () {
      bind();
    });
  } else {
    setTimeout(bind, 100);
  }
}

function bind() {
  Object.keys(bindings).forEach(function (className) {
    var binding = bindings[className];
    $("." + binding.className).not(".crosstalk-input-bound").each(function (i, el) {
      bindInstance(binding, el);
    });
  });
}

// Escape jQuery identifier
function $escape(val) {
  return val.replace(/([!"#$%&'()*+,.\/:;<=>?@\[\\\]^`{|}~])/g, "\\$1");
}

function bindInstance(binding, el) {
  var jsonEl = $(el).find("script[type='application/json'][data-for='" + $escape(el.id) + "']");
  var data = JSON.parse(jsonEl[0].innerText);

  var instance = binding.factory(el, data);
  $(el).data("crosstalk-instance", instance);
  $(el).addClass("crosstalk-input-bound");
}

if (global.Shiny) {
  (function () {
    var inputBinding = new global.Shiny.InputBinding();
    var $ = global.jQuery;
    $.extend(inputBinding, {
      find: function find(scope) {
        return $(scope).find(".crosstalk-input");
      },
      getId: function getId(el) {
        return el.id;
      },
      getValue: function getValue(el) {},
      setValue: function setValue(el, value) {},
      receiveMessage: function receiveMessage(el, data) {},
      subscribe: function subscribe(el, callback) {
        $(el).on("crosstalk-value-change.crosstalk", function (event) {
          callback(false);
        });
      },
      unsubscribe: function unsubscribe(el) {
        $(el).off(".crosstalk");
      }
    });
    global.Shiny.inputBindings.register(inputBinding, "crosstalk.inputBinding");
  })();
}
//# sourceMappingURL=input.js.map
