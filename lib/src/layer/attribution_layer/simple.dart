part of 'shared.dart';

/// A simple, classic style, attribution layer
///
/// Displayed as a padded translucent [backgroundColor] box with the following
/// text: 'flutter_map | © [source]', where [source] is wrapped with [onTap].
///
/// This layer is an anchored layer, so an additional [AnchoredLayer] should not
/// be used.
///
/// See also:
///
///  * [RichAttributionWidget], which is dynamic, supports more customization,
///    and has a more complex appearance.
@immutable
class SimpleAttributionWidget extends StatelessWidget
    with AnchoredLayerStatelessMixin
    implements AttributionWidget {
  /// Attribution text, such as 'OpenStreetMap contributors'
  final Text source;

  /// Callback called when [source] is tapped/clicked
  final VoidCallback? onTap;

  /// Color of the box containing the [source] text
  final Color? backgroundColor;

  /// Anchor the widget in a position of the map
  final Alignment alignment;

  /// A simple, classic style, attribution widget
  ///
  /// Displayed as a padded translucent white box with the following text:
  /// 'flutter_map | © [source]'.
  ///
  /// This layer is an anchored layer, so an additional [AnchoredLayer] should
  /// not be used.
  const SimpleAttributionWidget({
    super.key,
    required this.source,
    this.onTap,
    this.backgroundColor,
    this.alignment = Alignment.bottomRight,
  });

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Align(
      alignment: alignment,
      child: ColoredBox(
        color: backgroundColor ?? Theme.of(context).colorScheme.background,
        child: GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('flutter_map | © '),
                MouseRegion(
                  cursor: onTap == null
                      ? MouseCursor.defer
                      : SystemMouseCursors.click,
                  child: source,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
