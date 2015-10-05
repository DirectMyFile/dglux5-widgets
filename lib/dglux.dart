library dglux;

import "dart:async";
import "dart:convert";
import "dart:html";

class DGLux {
  StreamController<Map<String, dynamic>> _updatesController = new StreamController.broadcast();

  Completer _initializeCompleter = new Completer();

  int id;

  DGLux() {
    window.onMessage.listen((MessageEvent event) {
      if (event.data is! Map) return;

      Map<String, dynamic> data = event.data;

      if (data.containsKey("dgIframeInit")) {
        var dgIframeId = id = data["dgIframeInit"];

        window.parent.postMessage({
          "dgIframe": dgIframeId
        }, "*");

        _initializeCompleter.complete();
      }

      if (data.containsKey("dgIframeUpdate")) {
        var updates = data["updates"];

        updates = _processData(updates);

        _updatesController.add(updates);
      }

      if (data.containsKey("dgIframeMessage")) {
        var group = data["dgIframeMessageGroup"];
        var message = data["dgIframeMessage"];

        _onMessageController.add(new DGMessage(group, message));
      }
    });
  }

  static _processData(input) {
    if (input is Map) {
      for (var key in input.keys.toList()) {
        var value = input[key];
        if (value is Map && value.containsKey("cols") && value.containsKey("rows")) {
          input[key] = new Table.fromJSON(value);
        }
      }
      return input;
    } else if (input is List) {
      var out = [];
      for (var x in input) {
        out.add(_processData(x));
      }
    } else {
      return input;
    }
  }

  StreamController<DGMessage> _onMessageController = new StreamController<DGMessage>.broadcast();
  Stream<DGMessage> get onMessage => _onMessageController.stream;
  Stream<Map<String, dynamic>> get onUpdates => _updatesController.stream;
  Future get onInitialize => _initializeCompleter.future;

  void sendUpdates(Map<String, dynamic> input) {
    var out = {};
    for (var key in input.keys) {
      var value = input[key];

      if (value is Table) {
        value = value.toJSON();
      }

      out[key] = value;
    }

    window.parent.postMessage({
      "dgIframe": id,
      "changes": out
    }, "*");
  }

  void send(data, [String group = "*"]) {
    DGMessage msg;

    if (data is! DGMessage) {
      if (data is! String) {
        data = JSON.encode(data, toEncodable: (value) {
          if (value is Table) {
            return value.toJSON();
          } else {
            return value;
          }
        });
      }

      msg = new DGMessage(data, group);
    } else {
      msg = data;
    }

    window.parent.postMessage({
      "dgIframe": id,
      "dgIframeMessageGroup": msg.group,
      "dgIframeMessage": msg.message
    }, "*");
  }
}

class Table {
  final List<TableColumn> columns;
  final List<List<dynamic>> rows;

  Table(this.columns, this.rows);

  factory Table.fromJSON(input) {
    return new Table(input["cols"].map(
        (it) => new TableColumn.fromJSON(it)
      ).toList(),
      input["rows"].map((x) => DGLux._processData(x)).toList()
    );
  }

  Map toJSON() => {
    "cols": columns.map((it) => it.toJSON()).toList(),
    "rows": rows.map(
      (x) => x.map(
        (n) => n is Table ? n.toJSON() : n).toList()
    ).toList()
  };
}

class DGMessage {
  final String group;
  final String message;

  DGMessage(this.group, this.message);

  dynamic asJSON() {
    return JSON.decode(message);
  }
}

class TableColumn {
  final String name;
  final String type;

  TableColumn(this.name, this.type);

  factory TableColumn.fromJSON(input) {
    return new TableColumn(input["name"], input["type"]);
  }

  Map toJSON() => {
    "name": name,
    "type": type
  };
}
