import 'dart:math';

import 'package:diagram_editor/src/canvas_context/model/connection.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class ComponentData with ChangeNotifier {
  /// Unique id of this component.
  final String id;

  /// Position on the canvas.
  Offset get position => _position;

  set position(Offset position) {
    _position = position;
    notifyListeners();
  }

  Offset _position;

  /// Size of the component.
  Size get size => _size;

  set size(Size size) {
    _size = Size(
      max(size.width, minSize.width),
      max(size.height, minSize.height),
    );
    notifyListeners();
  }

  Size _size;

  /// Minimum size of the component.
  ///
  /// Size will be prevented from being set lower than this value.
  final Size minSize;

  /// Component type to distinguish components.
  ///
  /// You can use it for example to distinguish what [data] type this component has.
  final String type;

  /// This value determines if this component will be above or under other components.
  /// Higher value means on the top.
  int zOrder = 0;

  /// Defines to which components is this components connected and what is the [connectionId].
  ///
  /// The connection can be [ConnectionOut] for link going from this component
  /// or [ConnectionIn] for link going from another to this component.
  final List<Connection> connections = [];

  /// Dynamic data for you to define your own data for this component.
  final Object? data;

  /// Represents data of a component in the model.
  ComponentData({
    String? id,
    Offset position = Offset.zero,
    Size size = const Size(80, 80),
    this.minSize = const Size(4, 4),
    this.type = '',
    this.data,
  })  : assert(minSize <= size),
        id = id ?? const Uuid().v4(),
        _position = position,
        _size = size;

  /// Updates this component on the canvas.
  ///
  /// Use this function if you somehow changed the component data and you want to propagate the change to canvas.
  /// Usually this is already called in most functions such as [move] or [setSize] so it's not necessary to call it again.
  ///
  /// It calls [notifyListeners] function of [ChangeNotifier].
  void updateComponent() => notifyListeners();

  /// Translates the component by [offset] value.
  void move(Offset offset) => position += offset;

  /// Adds new connection to this component.
  ///
  /// Do not use it if you are not sure what you do. This is called in [connectTwoComponents] function.
  void addConnection(Connection connection) {
    connections.add(connection);
  }

  /// Removes existing connection.
  ///
  /// Do not use it if you are not sure what you do. This is called eg. in [removeLink] function.
  void removeConnection(String connectionId) {
    connections.removeWhere((conn) => conn.connectionId == connectionId);
  }

  /// Changes the component's size by [deltaSize].
  ///
  /// You cannot change its size to smaller than [minSize] defined on the component.
  void resizeDelta(Offset deltaSize) {
    var tempSize = size + deltaSize;
    if (tempSize.width < minSize.width) {
      tempSize = Size(minSize.width, tempSize.height);
    }
    if (tempSize.height < minSize.height) {
      tempSize = Size(tempSize.width, minSize.height);
    }
    size = tempSize;
  }

  /// Returns Offset position on this component from [alignment].
  ///
  /// [Alignment.topLeft] returns [Offset.zero]
  ///
  /// [Alignment.center] or [Alignment(0, 0)] returns the center coordinates on this component.
  ///
  /// [Alignment.bottomRight] returns offset that is equal to size of this component.
  Offset getPointOnComponent(Alignment alignment) {
    return Offset(
      size.width * ((alignment.x + 1) / 2),
      size.height * ((alignment.y + 1) / 2),
    );
  }

  @override
  String toString() {
    return 'Component data ($id), position: $position';
  }

  ComponentData.fromJson(
    Map<String, dynamic> json, {
    Function(Map<String, dynamic> json)? decodeCustomComponentData,
  })  : id = json['id'],
        _position = Offset(json['position'][0], json['position'][1]),
        _size = Size(json['size'][0], json['size'][1]),
        minSize = Size(json['min_size'][0], json['min_size'][1]),
        type = json['type'],
        zOrder = json['z_order'],
        data = decodeCustomComponentData?.call(json['dynamic_data']) {
    connections.addAll((json['connections'] as List)
        .map((connectionJson) => Connection.fromJson(connectionJson)));
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'position': [position.dx, position.dy],
        'size': [size.width, size.height],
        'min_size': [minSize.width, minSize.height],
        'type': type,
        'z_order': zOrder,
        'connections': connections,
        'dynamic_data': _dataToJson(data),
      };

  dynamic _dataToJson(dynamic data) {
    switch (data.runtimeType) {
      case String:
      case int:
      case double:
      case Null:
        return data;
      default:
        if (data is Iterable) {
          return data.map(_dataToJson);
        }
        if (data is Map<String, dynamic>) {
          return data.map((key, value) => MapEntry(key, _dataToJson(value)));
        }
        try {
          final map = data?.toMap();
          if (map is Map) return map;
        } on NoSuchMethodError {
          try {
            final json = data?.toJson();
            if (json is Map) return json;
          } on NoSuchMethodError {
            return data;
          }
        }
    }
  }
}
