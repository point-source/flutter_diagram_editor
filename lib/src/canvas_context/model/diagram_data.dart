import 'package:diagram_editor/diagram_editor.dart';

class DiagramData {
  final List<BaseComponentData> components;
  final List<LinkData> links;

  /// Contains list of all components and list of all links of the diagram
  DiagramData({
    required this.components,
    required this.links,
  });

  DiagramData.fromJson(
    Map<String, dynamic> json,
    BaseComponentData Function(Map<String, dynamic> json) decodeComponentData, {
    Function(Map<String, dynamic> json)? decodeCustomLinkData,
  })  : components = (json['components'] as List)
            .map((componentJson) => decodeComponentData(componentJson))
            .toList(),
        links = (json['links'] as List)
            .map((linkJson) => LinkData.fromJson(
                  linkJson,
                  decodeCustomLinkData: decodeCustomLinkData,
                ))
            .toList();

  Map<String, dynamic> toJson() => {
        'components': components,
        'links': links,
      };
}
