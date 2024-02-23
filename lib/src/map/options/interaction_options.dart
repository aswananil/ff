import 'package:flutter/services.dart';
import 'package:flutter_map/src/map/options/map_gestures.dart';
import 'package:meta/meta.dart';

/// Set interaction options for input gestures.
/// Most commonly used is [InteractionOptions.gestures].
@immutable
final class InteractionOptions {
  /// Enable or disable specific gestures. By default all gestures are enabled.
  /// If you want to disable all gestures or almost all gestures, use the
  /// [MapGestures.none] constructor.
  /// In case you want to disable only few gestures, use [MapGestures.all]
  /// and you can use the [MapGestures.noRotation] for an easy way to
  /// disable all rotation gestures.
  ///
  /// In addition you can specify your gestures via bitfield operations using
  /// the [MapGestures.bitfield] constructor together with the static
  /// fields in [InteractiveFlag].
  /// For more information see the documentation on [InteractiveFlag].
  final MapGestures gestures;

  /// Enable fling animation after panning if velocity is great enough.
  ///
  /// Defaults to true, this requires the `drag` gesture to be enabled.
  final bool dragFlingAnimation;

  /// Map starts to rotate when [twoFingerRotateThreshold] has been achieved
  /// or another multi finger gesture wins.
  /// Default is 0.1
  final double twoFingerRotateThreshold;

  /// Map starts to zoom when [twoFingerZoomThreshold] has been achieved or
  /// another multi finger gesture wins.
  /// Default is 0.1
  final double twoFingerZoomThreshold;

  /// Map starts to move when [twoFingerMoveThreshold] has been achieved or
  /// another multi finger gesture wins. This doesn't take any effect on drag
  /// gestures by a single pointer like a single finger.
  ///
  /// This option gets superseded by [twoFingerZoomThreshold] if
  /// [MapGestures.twoFingerMove] and [MapGestures.twoFingerZoom] are
  /// both active and the [twoFingerZoomThreshold] is reached.
  ///
  /// Default is 3.0.
  final double twoFingerMoveThreshold;

  /// The velocity how fast the map should zoom when using the scroll wheel
  /// of the mouse.
  /// Defaults to 0.01.
  final double scrollWheelVelocity;

  /// The velocity how fast the map should zoom when using the
  /// trackpad / touchpad.
  /// Defaults to 0.5.
  final double trackpadZoomVelocity;

  /// Override this option if you want to use custom keys for the key trigger
  /// drag rotate gesture (aka CTRL+drag rotate gesture).
  /// By default the left and right control key are both used.
  final List<LogicalKeyboardKey> keyTriggerDragRotateKeys;

  /// Default keys for the key press and drag to rotate gesture.
  static const defaultKeyTriggerDragRotateKeys = <LogicalKeyboardKey>[
    LogicalKeyboardKey.control,
    LogicalKeyboardKey.controlLeft,
    LogicalKeyboardKey.controlRight,
    LogicalKeyboardKey.shift,
    LogicalKeyboardKey.shiftLeft,
    LogicalKeyboardKey.shiftRight,
  ];

  /// Create a new [InteractionOptions] instance to be used
  /// in [MapOptions.interactionOptions].
  const InteractionOptions({
    this.gestures = const MapGestures.all(),
    this.twoFingerRotateThreshold = 0.1,
    this.twoFingerZoomThreshold = 0.01,
    this.twoFingerMoveThreshold = 3.0,
    this.scrollWheelVelocity = 0.01,
    this.trackpadZoomVelocity = 0.5,
    this.dragFlingAnimation = true,
    this.keyTriggerDragRotateKeys = defaultKeyTriggerDragRotateKeys,
  })  : assert(
          twoFingerRotateThreshold >= 0.0,
          'rotationThreshold needs to be a positive value',
        ),
        assert(
          twoFingerZoomThreshold >= 0.0,
          'pinchZoomThreshold needs to be a positive value',
        ),
        assert(
          twoFingerMoveThreshold >= 0.0,
          'pinchMoveThreshold needs to be a positive value',
        );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InteractionOptions &&
          gestures == other.gestures &&
          twoFingerRotateThreshold == other.twoFingerRotateThreshold &&
          twoFingerZoomThreshold == other.twoFingerZoomThreshold &&
          twoFingerMoveThreshold == other.twoFingerMoveThreshold &&
          keyTriggerDragRotateKeys == other.keyTriggerDragRotateKeys &&
          scrollWheelVelocity == other.scrollWheelVelocity);

  @override
  int get hashCode => Object.hash(
        gestures,
        twoFingerRotateThreshold,
        twoFingerZoomThreshold,
        twoFingerMoveThreshold,
        keyTriggerDragRotateKeys,
        scrollWheelVelocity,
      );
}
