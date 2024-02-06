part of 'marker_layer.dart';

/// A container for a [child] widget located at a geographic coordinate [point]
///
/// Some properties defaults will absorb the values from the parent
/// [MarkerLayer], if the reflected properties are defined there.
@immutable
class Marker {
  /// Provide an optional [Key] for the [Marker].
  /// This key will get passed through to the created marker widget.
  final Key? key;

  /// Coordinates of the marker
  ///
  /// This will be the center of the marker, assuming that [alignment] is
  /// [Alignment.center] (default).
  final LatLng point;

  /// Widget tree of the marker, sized by [width] & [height]
  ///
  /// The [Marker] itself is not a widget.
  final Widget child;

  /// Width of [child]
  final double width;

  /// Height of [child]
  final double height;

  /// Alignment of the marker relative to the normal center at [point]
  ///
  /// For example, [Alignment.topCenter] will mean the entire marker widget is
  /// located above the [point].
  ///
  /// The center of rotation (anchor) will be opposite this.
  ///
  /// Defaults to [Alignment.center] if also unset by [MarkerLayer].
  final Alignment? alignment;

  /// Whether to counter rotate this marker to the map's rotation, to keep a
  /// fixed orientation
  ///
  /// When `true`, this marker will always appear upright and vertical from the
  /// user's perspective. Defaults to `false` if also unset by [MarkerLayer].
  ///
  /// Note that this is not used to apply a custom rotation in degrees to the
  /// marker. Use a widget inside [builder] to perform this.
  final bool? rotate;

  /// Creates a container for a [child] widget located at a geographic coordinate
  /// [point]
  ///
  /// Some properties defaults will absorb the values from the parent
  /// [MarkerLayer], if the reflected properties are defined there.
  const Marker({
    this.key,
    required this.point,
    required this.child,
    this.width = 30,
    this.height = 30,
    this.alignment,
    this.rotate,
  });
}
