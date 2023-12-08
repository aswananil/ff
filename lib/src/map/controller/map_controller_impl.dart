import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/gestures/map_interactive_viewer.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_math/vector_math_64.dart';

/// Implements [MapController] whilst exposing methods for internal use which
/// should not be visible to the user (e.g. for setting the current camera).
/// This controller is for internal use. All updates to the state should be done
/// by calling methods of this class to ensure consistency.
class MapControllerImpl extends ValueNotifier<_MapControllerState>
    implements MapController {
  final _mapEventStreamController = StreamController<MapEvent>.broadcast();

  late final MapInteractiveViewerState _interactiveViewerState;

  MapControllerImpl([MapOptions? options])
      : super(
          _MapControllerState(
            options: options,
            camera: options == null ? null : MapCamera.initialCamera(options),
          ),
        );

  /// Link the viewer state with the controller. This should be done once when
  /// the FlutterMapInteractiveViewerState is initialized.
  set interactiveViewerState(
    MapInteractiveViewerState interactiveViewerState,
  ) =>
      _interactiveViewerState = interactiveViewerState;

  StreamSink<MapEvent> get _mapEventSink => _mapEventStreamController.sink;

  @override
  Stream<MapEvent> get mapEventStream => _mapEventStreamController.stream;

  MapOptions get options {
    return value.options ??
        (throw Exception('You need to have the FlutterMap widget rendered at '
            'least once before using the MapController.'));
  }

  @override
  MapCamera get camera {
    return value.camera ??
        (throw Exception('You need to have the FlutterMap widget rendered at '
            'least once before using the MapController.'));
  }

  /// This setter should only be called in this class or within tests. Changes
  /// to the [_MapControllerState] should be done via methods in this class.
  @visibleForTesting
  @override
  // ignore: library_private_types_in_public_api
  set value(_MapControllerState value) => super.value = value;

  @override
  bool move(
    LatLng center,
    double zoom, {
    Offset offset = Offset.zero,
    String? id,
  }) =>
      moveRaw(
        center,
        zoom,
        offset: offset,
        hasGesture: false,
        source: MapEventSource.mapController,
        id: id,
      );

  @override
  bool rotate(double degree, {String? id}) => rotateRaw(
        degree,
        hasGesture: false,
        source: MapEventSource.mapController,
        id: id,
      );

  @override
  MoveAndRotateResult rotateAroundPoint(
    double degree, {
    Point<double>? point,
    Offset? offset,
    String? id,
  }) =>
      rotateAroundPointRaw(
        degree,
        point: point,
        offset: offset,
        hasGesture: false,
        source: MapEventSource.mapController,
        id: id,
      );

  @override
  MoveAndRotateResult moveAndRotate(
    LatLng center,
    double zoom,
    double degree, {
    String? id,
  }) =>
      moveAndRotateRaw(
        center,
        zoom,
        degree,
        offset: Offset.zero,
        hasGesture: false,
        source: MapEventSource.mapController,
        id: id,
      );

  @override
  bool fitCamera(CameraFit cameraFit) => fitCameraRaw(cameraFit);

  bool moveRaw(
    LatLng newCenter,
    double newZoom, {
    Offset offset = Offset.zero,
    required bool hasGesture,
    required MapEventSource source,
    String? id,
  }) {
    // Algorithm thanks to https://github.com/tlserver/flutter_map_location_marker
    if (offset != Offset.zero) {
      final newPoint = camera.project(newCenter, newZoom);
      newCenter = camera.unproject(
        camera.rotatePoint(
          newPoint,
          newPoint - Point(offset.dx, offset.dy),
        ),
        newZoom,
      );
    }

    MapCamera? newCamera = camera.withPosition(
      center: newCenter,
      zoom: camera.clampZoom(newZoom),
    );

    newCamera = options.cameraConstraint.constrain(newCamera);
    if (newCamera == null ||
        (newCamera.center == camera.center && newCamera.zoom == camera.zoom)) {
      return false;
    }

    final oldCamera = camera;
    value = value.withMapCamera(newCamera);

    final movementEvent = MapEventWithMove.fromSource(
      oldCamera: oldCamera,
      camera: camera,
      hasGesture: hasGesture,
      source: source,
      id: id,
    );
    if (movementEvent != null) _emitMapEvent(movementEvent);

    options.onPositionChanged?.call(
      MapPosition(
        center: newCenter,
        bounds: camera.visibleBounds,
        zoom: newZoom,
        hasGesture: hasGesture,
      ),
      hasGesture,
    );

    return true;
  }

  bool rotateRaw(
    double newRotation, {
    required bool hasGesture,
    required MapEventSource source,
    String? id,
  }) {
    if (newRotation != camera.rotation) {
      final newCamera = options.cameraConstraint.constrain(
        camera.withRotation(newRotation),
      );
      if (newCamera == null) return false;

      final oldCamera = camera;

      // Update camera then emit events and callbacks
      value = value.withMapCamera(newCamera);

      _emitMapEvent(
        MapEventRotate(
          id: id,
          source: source,
          oldCamera: oldCamera,
          camera: camera,
        ),
      );
      return true;
    }

    return false;
  }

  MoveAndRotateResult rotateAroundPointRaw(
    double degree, {
    required Point<double>? point,
    required Offset? offset,
    required bool hasGesture,
    required MapEventSource source,
    String? id,
  }) {
    if (point != null && offset != null) {
      throw ArgumentError('Only one of `point` or `offset` may be non-null');
    }
    if (point == null && offset == null) {
      throw ArgumentError('One of `point` or `offset` must be non-null');
    }

    if (degree == camera.rotation) {
      return const (moveSuccess: false, rotateSuccess: false);
    }

    if (offset == Offset.zero) {
      return (
        moveSuccess: true,
        rotateSuccess: rotateRaw(
          degree,
          hasGesture: hasGesture,
          source: source,
          id: id,
        ),
      );
    }

    final rotationDiff = degree - camera.rotation;
    final rotationCenter = camera.project(camera.center) +
        (point != null
                ? (point - (camera.nonRotatedSize / 2.0))
                : Point(offset!.dx, offset.dy))
            .rotate(camera.rotationRad);

    return (
      moveSuccess: moveRaw(
        camera.unproject(
          rotationCenter +
              (camera.project(camera.center) - rotationCenter)
                  .rotate(degrees2Radians * rotationDiff),
        ),
        camera.zoom,
        hasGesture: hasGesture,
        source: source,
        id: id,
      ),
      rotateSuccess: rotateRaw(
        camera.rotation + rotationDiff,
        hasGesture: hasGesture,
        source: source,
        id: id,
      ),
    );
  }

  MoveAndRotateResult moveAndRotateRaw(
    LatLng newCenter,
    double newZoom,
    double newRotation, {
    required Offset offset,
    required bool hasGesture,
    required MapEventSource source,
    String? id,
  }) =>
      (
        moveSuccess: moveRaw(
          newCenter,
          newZoom,
          offset: offset,
          hasGesture: hasGesture,
          source: source,
          id: id,
        ),
        rotateSuccess: rotateRaw(
          newRotation,
          id: id,
          source: source,
          hasGesture: hasGesture,
        ),
      );

  bool fitCameraRaw(
    CameraFit cameraFit, {
    Offset offset = Offset.zero,
  }) {
    final fitted = cameraFit.fit(camera);
    return moveRaw(
      fitted.center,
      fitted.zoom,
      offset: offset,
      hasGesture: false,
      source: MapEventSource.mapController,
    );
  }

  bool setNonRotatedSizeWithoutEmittingEvent(
    Point<double> nonRotatedSize,
  ) {
    if (nonRotatedSize != MapCamera.kImpossibleSize &&
        nonRotatedSize != camera.nonRotatedSize) {
      value = value.withMapCamera(camera.withNonRotatedSize(nonRotatedSize));
      return true;
    }

    return false;
  }

  set options(MapOptions newOptions) {
    assert(
      newOptions != value.options,
      'Should not update options unless they change',
    );

    final newCamera = value.camera?.withOptions(newOptions) ??
        MapCamera.initialCamera(newOptions);

    assert(
      newOptions.cameraConstraint.constrain(newCamera) == newCamera,
      'MapCamera is no longer within the cameraConstraint after an option change.',
    );

    if (value.options != null &&
        value.options!.interactionOptions != newOptions.interactionOptions) {
      _interactiveViewerState.updateGestures(
        value.options!.interactionOptions,
        newOptions.interactionOptions,
      );
    }

    value = _MapControllerState(
      options: newOptions,
      camera: newCamera,
    );
  }

  /// To be called when a gesture that causes movement starts.
  void moveStarted(MapEventSource source) {
    _emitMapEvent(
      MapEventMoveStart(
        camera: camera,
        source: source,
      ),
    );
  }

  /// To be called when an ongoing drag movement updates.
  void dragUpdated(MapEventSource source, Offset offset) {
    final oldCenterPt = camera.project(camera.center);

    final newCenterPt = oldCenterPt + offset.toPoint();
    final newCenter = camera.unproject(newCenterPt);

    moveRaw(
      newCenter,
      camera.zoom,
      hasGesture: true,
      source: source,
    );
  }

  /// To be called when a drag gesture ends.
  void moveEnded(MapEventSource source) {
    _emitMapEvent(
      MapEventMoveEnd(
        camera: camera,
        source: source,
      ),
    );
  }

  /// To be called when a rotation gesture starts.
  void rotateStarted(MapEventSource source) {
    _emitMapEvent(
      MapEventRotateStart(
        camera: camera,
        source: source,
      ),
    );
  }

  /// To be called when a rotation gesture ends.
  void rotateEnded(MapEventSource source) {
    _emitMapEvent(
      MapEventRotateEnd(
        camera: camera,
        source: source,
      ),
    );
  }

  /// To be called when a fling gesture starts.
  void flingStarted(MapEventSource source) {
    _emitMapEvent(
      MapEventFlingAnimationStart(
        camera: camera,
        source: MapEventSource.flingAnimationController,
      ),
    );
  }

  /// To be called when a fling gesture ends.
  void flingEnded(MapEventSource source) {
    _emitMapEvent(
      MapEventFlingAnimationEnd(
        camera: camera,
        source: source,
      ),
    );
  }

  /// To be called when a fling gesture does not start.
  void flingNotStarted(MapEventSource source) {
    _emitMapEvent(
      MapEventFlingAnimationNotStarted(
        camera: camera,
        source: source,
      ),
    );
  }

  /// To be called when a double tap zoom starts.
  void doubleTapZoomStarted(MapEventSource source) {
    _emitMapEvent(
      MapEventDoubleTapZoomStart(
        camera: camera,
        source: source,
      ),
    );
  }

  /// To be called when a double tap zoom ends.
  void doubleTapZoomEnded(MapEventSource source) {
    _emitMapEvent(
      MapEventDoubleTapZoomEnd(
        camera: camera,
        source: source,
      ),
    );
  }

  void tapped(
    MapEventSource source,
    TapPosition tapPosition,
    LatLng position,
  ) {
    options.onTap?.call(tapPosition, position);
    _emitMapEvent(
      MapEventTap(
        tapPosition: position,
        camera: camera,
        source: source,
      ),
    );
  }

  void secondaryTapped(
    MapEventSource source,
    TapPosition tapPosition,
    LatLng position,
  ) {
    options.onSecondaryTap?.call(tapPosition, position);
    _emitMapEvent(
      MapEventSecondaryTap(
        tapPosition: position,
        camera: camera,
        source: source,
      ),
    );
  }

  void longPressed(
    MapEventSource source,
    TapPosition tapPosition,
    LatLng position,
  ) {
    options.onLongPress?.call(tapPosition, position);
    _emitMapEvent(
      MapEventLongPress(
        tapPosition: position,
        camera: camera,
        source: MapEventSource.longPress,
      ),
    );
  }

  /// To be called when the map's size constraints change.
  void nonRotatedSizeChange(
    MapEventSource source,
    MapCamera oldCamera,
    MapCamera newCamera,
  ) {
    _emitMapEvent(
      MapEventNonRotatedSizeChange(
        source: MapEventSource.nonRotatedSizeChange,
        oldCamera: oldCamera,
        camera: newCamera,
      ),
    );
  }

  void _emitMapEvent(MapEvent event) {
    if (event.source == MapEventSource.mapController && event is MapEventMove) {
      _interactiveViewerState.interruptAnimatedMovement(event);
    }

    options.onMapEvent?.call(event);

    _mapEventSink.add(event);
  }

  @override
  void dispose() {
    _mapEventStreamController.close();
    super.dispose();
  }
}

@immutable
class _MapControllerState {
  final MapCamera? camera;
  final MapOptions? options;

  const _MapControllerState({
    required this.options,
    required this.camera,
  });

  _MapControllerState withMapCamera(MapCamera camera) => _MapControllerState(
        options: options,
        camera: camera,
      );
}
