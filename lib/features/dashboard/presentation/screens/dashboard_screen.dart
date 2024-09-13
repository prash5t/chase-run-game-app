import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late ARKitController arkitController;
  final double planeDistance = 1.0; // Distance in meters from the camera

  @override
  void dispose() {
    arkitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ARKit with Physics'),
      ),
      body: ARKitSceneView(
        planeDetection: ARPlaneDetection.horizontal, // Enable plane detection
        onARKitViewCreated: onARKitViewCreated,
        enableTapRecognizer: true, // Enable tap for placing objects dynamically
      ),
    );
  }

  void onARKitViewCreated(ARKitController controller) {
    arkitController = controller;

    // Handle tap to add balls with physics
    arkitController.onARTap = (List<ARKitTestResult> results) {
      if (results.isNotEmpty) {
        final tapResult = results.firstWhere(
            (result) => result.type == ARKitHitTestResultType.featurePoint);
        final position = Vector3(
          tapResult.worldTransform.getTranslation().x,
          tapResult.worldTransform.getTranslation().y,
          tapResult.worldTransform.getTranslation().z,
        );
        addBallWithPhysics(position);
      }
    };

    // Initialize the plane at a fixed distance from the camera
    initializePlane();
  }

  // Function to add a plane at a specified position
  void initializePlane() {
    arkitController.cameraPosition().then((cameraPosition) {
      if (cameraPosition != null) {
        final planePosition = Vector3(
          cameraPosition.x,
          cameraPosition.y - 0.5, // Adjust height if needed
          cameraPosition.z +
              planeDistance, // Position plane in front of the camera
        );
        addPlane(planePosition);
      }
    });
  }

  // Function to add a plane at a specified position
  void addPlane(Vector3 position) {
    final plane = ARKitPlane(
      width: 1.0, // Set width and height based on your needs
      height: 1.0,
    );

    final planeNode = ARKitNode(
      geometry: plane,
      position: position,
      physicsBody: ARKitPhysicsBody(
        ARKitPhysicsBodyType.staticType,
        shape: ARKitPhysicsShape(plane),
      ),
    );

    arkitController.add(planeNode);
  }

  // Function to add a ball with physics
  void addBallWithPhysics(Vector3 position) {
    final physicsBody = ARKitPhysicsBody(
      ARKitPhysicsBodyType.dynamicType,
      shape: ARKitPhysicsShape(ARKitSphere(radius: 0.05)),
    );

    final ballNode = ARKitNode(
      geometry: ARKitSphere(radius: 0.05),
      position: position,
      physicsBody:
          physicsBody, // Attach physics body to enable gravity and collisions
    );

    arkitController.add(ballNode);
  }
}
