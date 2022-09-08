import 'dart:math' as math;

import 'package:diagram_editor/diagram_editor.dart';
import 'package:flutter/material.dart';

void main() => runApp(const DiagramApp());

class DiagramApp extends StatefulWidget {
  const DiagramApp({Key? key}) : super(key: key);

  @override
  DiagramAppState createState() => DiagramAppState();
}

class DiagramAppState extends State<DiagramApp> {
  MyPolicySet myPolicySet = MyPolicySet();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Container(color: Colors.grey),
              Padding(
                padding: const EdgeInsets.all(16),
                child: DiagramEditor(
                  diagramEditorContext:
                      DiagramEditorContext(policySet: myPolicySet),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(0),
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => myPolicySet.deleteAllComponents(),
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('delete all'),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () => myPolicySet.serialize(),
                      child: const Text('serialize'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => myPolicySet.deserialize(),
                      child: const Text('deserialize'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ComponentData extends BaseComponentData {
  ComponentData(
      {super.id,
      super.position,
      super.size,
      super.minSize,
      super.zOrder,
      this.isHighlightVisible = false,
      Color? color})
      : color = color ??
            Color((math.Random().nextDouble() * 0xFFFFFF).toInt())
                .withOpacity(1.0);

  bool isHighlightVisible;
  Color color;

  showHighlight() {
    isHighlightVisible = true;
  }

  hideHighlight() {
    isHighlightVisible = false;
  }

  // Function used to deserialize the diagram. Must be passed to `canvasWriter.model.deserializeDiagram` for proper deserialization.
  factory ComponentData.fromJson(Map<String, dynamic> json) {
    return ComponentData(
      id: json['id'],
      position: Offset(json['position'][0], json['position'][1]),
      size: Size(json['size'][0], json['size'][1]),
      minSize: Size(json['min_size'][0], json['min_size'][1]),
      zOrder: json['z_order'],
      isHighlightVisible: json['isHighlightVisible'],
      color: Color(int.parse(json['color'], radix: 16)),
    )..connections.addAll((json['connections'] as List)
        .map((connectionJson) => Connection.fromJson(connectionJson)));
  }

  // Function used to serialization of the diagram. E.g. to save to a file.
  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'isHighlightVisible': isHighlightVisible,
        'color': color.toString().split('(0x')[1].split(')')[0],
      };
}

// A set of policies compound of mixins. There are some custom policy implementations and some policies defined by diagram_editor library.
class MyPolicySet extends PolicySet
    with
        MyInitPolicy,
        MyComponentDesignPolicy,
        MyCanvasPolicy,
        MyComponentPolicy,
        CustomPolicy,
        CanvasControlPolicy,
        LinkControlPolicy,
        LinkJointControlPolicy,
        LinkAttachmentRectPolicy {}

// A place where you can init the canvas or your diagram (eg. load an existing diagram).
mixin MyInitPolicy implements InitPolicy {
  @override
  initializeDiagramEditor() {
    canvasWriter.state.setCanvasColor(Colors.grey[300]!);
  }
}

// This is the place where you can design a component.
// Use switch on componentData.type or componentData.data to define different component designs.
mixin MyComponentDesignPolicy implements ComponentDesignPolicy {
  @override
  Widget showComponentBody(BaseComponentData componentData) {
    componentData = componentData as ComponentData;
    return Container(
      decoration: BoxDecoration(
        color: componentData.color,
        border: Border.all(
          width: 2,
          color: componentData.isHighlightVisible ? Colors.pink : Colors.black,
        ),
      ),
      child: const Center(child: Text('component')),
    );
  }
}

// You can override the behavior of any gesture on canvas here.
// Note that it also implements CustomPolicy where own variables and functions can be defined and used here.
mixin MyCanvasPolicy implements CanvasPolicy, CustomPolicy {
  @override
  onCanvasTapUp(TapUpDetails details) {
    canvasWriter.model.hideAllLinkJoints();
    if (selectedComponentId != null) {
      hideComponentHighlight(selectedComponentId);
    } else {
      canvasWriter.model.addComponent(
        ComponentData(
          size: const Size(96, 72),
          position:
              canvasReader.state.fromCanvasCoordinates(details.localPosition),
        ),
      );
    }
  }
}

// Mixin where component behaviour is defined. In this example it is the movement, highlight and connecting two components.
mixin MyComponentPolicy implements ComponentPolicy, CustomPolicy {
  // variable used to calculate delta offset to move the component.
  late Offset lastFocalPoint;

  @override
  onComponentTap(String componentId) {
    canvasWriter.model.hideAllLinkJoints();

    bool connected = connectComponents(selectedComponentId, componentId);
    hideComponentHighlight(selectedComponentId);
    if (!connected) {
      highlightComponent(componentId);
    }
  }

  @override
  onComponentLongPress(String componentId) {
    hideComponentHighlight(selectedComponentId);
    canvasWriter.model.hideAllLinkJoints();
    canvasWriter.model.removeComponent(componentId);
  }

  @override
  onComponentScaleStart(componentId, details) {
    lastFocalPoint = details.localFocalPoint;
  }

  @override
  onComponentScaleUpdate(componentId, details) {
    Offset positionDelta = details.localFocalPoint - lastFocalPoint;
    canvasWriter.model.moveComponent(componentId, positionDelta);
    lastFocalPoint = details.localFocalPoint;
  }

  // This function tests if it's possible to connect the components and if yes, connects them
  bool connectComponents(String? sourceComponentId, String? targetComponentId) {
    if (sourceComponentId == null || targetComponentId == null) {
      return false;
    }
    // tests if the ids are not same (the same component)
    if (sourceComponentId == targetComponentId) {
      return false;
    }
    // tests if the connection between two components already exists (one way)
    if (canvasReader.model.getComponent(sourceComponentId).connections.any(
          (connection) =>
              (connection is ConnectionOut) &&
              (connection.otherComponentId == targetComponentId),
        )) {
      return false;
    }

    // This connects two components (creates a link between), you can define the design of the link with LinkStyle.
    canvasWriter.model.connectTwoComponents(
      sourceComponentId: sourceComponentId,
      targetComponentId: targetComponentId,
      linkStyle: const LinkStyle(
        arrowType: ArrowType.pointedArrow,
        lineWidth: 1.5,
        backArrowType: ArrowType.centerCircle,
      ),
    );

    return true;
  }
}

// You can create your own Policy to define own variables and functions with canvasReader and canvasWriter.
mixin CustomPolicy implements PolicySet {
  String? selectedComponentId;
  String serializedDiagram = '{"components": [], "links": []}';

  highlightComponent(String componentId) {
    final componentData =
        canvasReader.model.getComponent(componentId) as ComponentData;
    componentData.showHighlight();
    componentData.updateComponent();
    selectedComponentId = componentId;
  }

  hideComponentHighlight(String? componentId) {
    if (componentId != null) {
      final componentData =
          canvasReader.model.getComponent(componentId) as ComponentData;
      componentData.hideHighlight();
      componentData.updateComponent();
      selectedComponentId = null;
    }
  }

  deleteAllComponents() {
    selectedComponentId = null;
    canvasWriter.model.removeAllComponents();
  }

  // Save the diagram to String in json format.
  serialize() {
    serializedDiagram = canvasReader.model.serializeDiagram();
  }

  // Load the diagram from json format. Do it cautiously, to prevent unstable state remove the previous diagram (id collision can happen).
  deserialize() {
    canvasWriter.model.removeAllComponents();
    canvasWriter.model.deserializeDiagram(
      serializedDiagram,
      ComponentData.fromJson,
      decodeCustomLinkData: null,
    );
  }
}
