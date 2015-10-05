window.DGLux5 = {
  "_": {
    "params": {},
    "initialized": false,
    "onInitialized": []
  },
  "onInitialized": function (func) {
    DGLux5._.onInitialized.push(func);
  },
  "parameter": function (name, handler) {
    DGLux5._.params[name] = handler;
    return DGLux5;
  },
  "update": function (map) {
    window.parent.postMessage({
      "dgIframe": window.DGLux5._.id,
      "changes": map
    }, "*");
  },
  "setup": function (params) {
    DGLux5._.params = params;
    if (this._.initialized === true) {
      return;
    }

    this._.initialized = true;

    function onMessage(e) {
      var data = e.data;
      console.log("Message: " + e);
      if (typeof data === "object") {
        if (data.hasOwnProperty("$builtinTypeInfo") && typeof data._strings === "object") {
          data = this.fixDartMap(data);
        }

        if (data.hasOwnProperty("dgIframeInit")) {
          var dgIframeId = data["dgIframeInit"];
          window.DGLux5._.id = dgIframeId;
          if (window.parent != null) {
            window.parent.postMessage({
              'dgIframe': dgIframeId
            }, '*');
          }

          for (var i in DGLux5._.onInitialized) {
            DGLux5._.onInitialized[i]();
          }
        } else if (data.hasOwnProperty("dgIframeUpdate")) {
          var updates = data["updates"];
          if (typeof updates === "object") {
            for (var key in DGLux5._.params) {
              if (DGLux5._.params.hasOwnProperty(key) && updates.hasOwnProperty(key)) {
                DGLux5._.params[key](updates[key]);
              }
            }
          }
        }
      }
    }

    window.addEventListener("message", onMessage);

    return DGLux5;
  },
  "fixDartMap": function (map) {
    var rslt = {};
    var strings = map._strings;
    for (var key in strings) {
      if (strings.hasOwnProperty(key)) {
        rslt[key] = strings[key]._value;
      }
    }
    return rslt;
  }
};
