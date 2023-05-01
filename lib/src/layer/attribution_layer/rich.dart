import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:meta/meta.dart';

/// Position to anchor [RichAttributionWidget] to relative to the [FlutterMap]
///
/// Reflects standard [Alignment] through [real], but limits to the only
/// supported options.
enum AttributionAlignment {
  /// The bottom left corner
  bottomLeft(Alignment.bottomLeft),

  /// The bottom right corner
  bottomRight(Alignment.bottomRight);

  /// Position to anchor [RichAttributionWidget] to relative to the [FlutterMap]
  ///
  /// Reflects standard [Alignment] through [real], but limits to the only
  /// supported options.
  const AttributionAlignment(this.real);

  /// Reflects the standard [Alignment]
  @internal
  final Alignment real;
}

/// A prebuilt dynamic attribution layer that supports both logos and text
/// through [SourceAttribution]s
///
/// [TextSourceAttribution]s are shown in a popup box that can be visible or
/// invisible. Its state is toggled by a tri-state [openButton]/[closeButton] :
///   1. Not hovered, not opened: faded button, invisible box
///   2. Hovered, not opened: full opacity button, invisible box
///   3. Opened: full opacity button, visible box
///
/// The hover state on mobile devices is unspecified, but the behaviour is
/// usually inconsequential on mobile devices anyway, due to the fingertip
/// covering the entire button.
///
/// [LogoSourceAttribution]s are shown adjacent to the open/close button, to
/// comply with some stricter tile server requirements (such as Mapbox). These
/// are usually supplemented with a [TextSourceAttribution].
///
/// The popup box also closes automatically on any interaction with the map.
///
/// Animations are built in by default, and configured/handled through
/// [RichAttributionWidgetAnimation] - see that class and the [animationConfig]
/// property for more information. By default, a simple fade/opacity animation
/// is provided by [FadeRAWA]. [ScaleRAWA] is also available.
///
/// Read the documentation on the individual properties for more information and
/// customizability.
class RichAttributionWidget extends StatefulWidget {
  /// List of attributions to display
  ///
  /// [TextSourceAttribution]s are shown in a popup box (toggled by a tap/click
  /// on the [openButton]/[closeButton]), unlike [LogoSourceAttribution], which
  /// are visible permanently adjacent to the open/close button.
  final List<SourceAttribution> attributions;

  /// The position in which to anchor this widget
  final AttributionAlignment alignment;

  /// The widget (usually an [IconButton]) to display when the popup box is
  /// closed, that opens the popup box via the `open` callback
  final Widget Function(BuildContext context, VoidCallback open)? openButton;

  /// The widget (usually an [IconButton]) to display when the popup box is open,
  /// that closes the popup box via the `close` callback
  final Widget Function(BuildContext context, VoidCallback close)? closeButton;

  /// The color to use as the popup box's background color, defaulting to the
  /// [Theme]s background color
  final Color? popupBackgroundColor;

  /// The radius of the edges of the popup box
  final BorderRadius? popupBorderRadius;

  /// The height of the permanent row in which is found the popup menu toggle
  /// button
  ///
  /// Also determines spacing between the items within the row.
  ///
  /// Also set [LogoSourceAttribution.height] to the same value, if adjusted.
  final double permanentHeight;

  /// Whether to add an additional attribution logo and text for 'flutter_map'
  final bool showFlutterMapAttribution;

  /// Animation configuration, through the properties and handler/builder
  /// defined by a [RichAttributionWidgetAnimation] implementation
  ///
  /// Can be extensivley customized by implementing a custom
  /// [RichAttributionWidgetAnimation], or the prebuilt [FadeRAWA] and
  /// [ScaleRAWA] animations can be used with limited customization.
  final RichAttributionWidgetAnimation animationConfig;

  /// If not [Duration.zero] (default), the popup box will be open by default and
  /// hidden this long after the map is initialised
  ///
  /// This is useful with certain sources/tile servers that make immediate
  /// attribution mandatory and are not attributed with a permanently visible
  /// [LogoSourceAttribution].
  final Duration popupInitialDisplayDuration;

  /// A prebuilt dynamic attribution layer that supports both logos and text
  /// through [SourceAttribution]s
  ///
  /// [TextSourceAttribution]s are shown in a popup box that can be visible or
  /// invisible. Its state is toggled by a tri-state [openButton]/[closeButton] :
  ///   1. Not hovered, not opened: faded button, invisible box
  ///   2. Hovered, not opened: full opacity button, invisible box
  ///   3. Opened: full opacity button, visible box
  ///
  /// The hover state on mobile devices is unspecified, but the behaviour is
  /// usually inconsequential on mobile devices anyway, due to the fingertip
  /// covering the entire button.
  ///
  /// [LogoSourceAttribution]s are shown adjacent to the open/close button, to
  /// comply with some stricter tile server requirements (such as Mapbox). These
  /// are usually supplemented with a [TextSourceAttribution].
  ///
  /// The popup box also closes automatically on any interaction with the map.
  ///
  /// Animations are built in by default, and configured/handled through
  /// [RichAttributionWidgetAnimation] - see that class and the [animationConfig]
  /// property for more information. By default, a simple fade/opacity animation
  /// is provided by [FadeRAWA]. [ScaleRAWA] is also available.
  ///
  /// Read the documentation on the individual properties for more information
  /// and customizability.
  const RichAttributionWidget({
    super.key,
    required this.attributions,
    this.alignment = AttributionAlignment.bottomRight,
    this.openButton,
    this.closeButton,
    this.popupBackgroundColor,
    this.popupBorderRadius,
    this.permanentHeight = 24,
    this.showFlutterMapAttribution = true,
    this.animationConfig = const FadeRAWA(),
    this.popupInitialDisplayDuration = Duration.zero,
  });

  @override
  State<StatefulWidget> createState() => RichAttributionWidgetState();
}

class RichAttributionWidgetState extends State<RichAttributionWidget> {
  StreamSubscription<MapEvent>? mapEventSubscription;

  final persistentAttributionKey = GlobalKey();
  Size? persistentAttributionSize;

  late bool popupExpanded = widget.popupInitialDisplayDuration != Duration.zero;
  bool persistentHovered = false;

  @override
  void initState() {
    super.initState();

    if (popupExpanded) {
      Future.delayed(
        widget.popupInitialDisplayDuration,
        () => setState(() => popupExpanded = false),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => WidgetsBinding.instance.addPostFrameCallback(
        (_) => setState(
          () => persistentAttributionSize =
              (persistentAttributionKey.currentContext!.findRenderObject()
                      as RenderBox)
                  .size,
        ),
      ),
    );
  }

  @override
  void dispose() {
    mapEventSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final persistentAttributionItems = [
      ...List<Widget>.from(
        widget.attributions.whereType<LogoSourceAttribution>(),
        growable: false,
      ).interleave(SizedBox(width: widget.permanentHeight / 1.5)),
      if (widget.showFlutterMapAttribution)
        LogoSourceAttribution(
          Image.asset(
            'lib/assets/flutter_map_logo.png',
            package: 'flutter_map',
          ),
          tooltip: 'flutter_map',
          height: widget.permanentHeight,
        ),
      SizedBox(width: widget.permanentHeight * 0.1),
      AnimatedSwitcher(
        switchInCurve: widget.animationConfig.buttonCurve,
        switchOutCurve: widget.animationConfig.buttonCurve,
        duration: widget.animationConfig.buttonDuration,
        child: popupExpanded
            ? (widget.closeButton ??
                (context, close) => IconButton(
                      onPressed: close,
                      icon: Icon(
                        Icons.cancel_outlined,
                        color: Theme.of(context).textTheme.titleSmall?.color ??
                            Colors.black,
                        size: widget.permanentHeight,
                      ),
                    ))(
                context,
                () => setState(() => popupExpanded = false),
              )
            : (widget.openButton ??
                (context, open) => IconButton(
                      onPressed: open,
                      tooltip: 'Attributions',
                      icon: Icon(
                        Icons.info_outlined,
                        color: Colors.black,
                        size: widget.permanentHeight,
                      ),
                    ))(
                context,
                () {
                  setState(() => popupExpanded = true);
                  mapEventSubscription = FlutterMapState.maybeOf(context)!
                      .mapController
                      .mapEventStream
                      .listen((e) {
                    setState(() => popupExpanded = false);
                    mapEventSubscription?.cancel();
                  });
                },
              ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: widget.alignment.real,
        child: Stack(
          alignment: widget.alignment.real,
          children: [
            if (persistentAttributionSize != null)
              Padding(
                padding: const EdgeInsets.all(6),
                child: widget.animationConfig.popupAnimationBuilder(
                  context: context,
                  isExpanded: popupExpanded,
                  config: widget,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.popupBackgroundColor ??
                          Theme.of(context).colorScheme.background,
                      border: Border.all(width: 0, style: BorderStyle.none),
                      borderRadius: widget.popupBorderRadius ??
                          BorderRadius.only(
                            topLeft: const Radius.circular(10),
                            topRight: const Radius.circular(10),
                            bottomLeft: widget.alignment ==
                                    AttributionAlignment.bottomLeft
                                ? Radius.zero
                                : const Radius.circular(10),
                            bottomRight: widget.alignment ==
                                    AttributionAlignment.bottomRight
                                ? Radius.zero
                                : const Radius.circular(10),
                          ),
                    ),
                    constraints: BoxConstraints(
                      minWidth: constraints.maxWidth < 420
                          ? constraints.maxWidth
                          : persistentAttributionSize!.width,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...widget.attributions
                              .whereType<TextSourceAttribution>(),
                          const TextSourceAttribution(
                            "Made with 'flutter_map'",
                            prependCopyright: false,
                            textStyle: TextStyle(fontStyle: FontStyle.italic),
                          ),
                          SizedBox(height: (widget.permanentHeight - 24) + 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            MouseRegion(
              key: persistentAttributionKey,
              onEnter: (_) => setState(() => persistentHovered = true),
              onExit: (_) => setState(() => persistentHovered = false),
              cursor: SystemMouseCursors.click,
              child: AnimatedOpacity(
                opacity: persistentHovered || popupExpanded ? 1 : 0.5,
                curve: widget.animationConfig.buttonCurve,
                duration: widget.animationConfig.buttonDuration,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: FittedBox(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children:
                          widget.alignment == AttributionAlignment.bottomLeft
                              ? persistentAttributionItems.reversed.toList()
                              : persistentAttributionItems,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension _ListExt<E> on List<E> {
  Iterable<E> interleave(E separator) sync* {
    for (int i = 0; i < length; i++) {
      yield this[i];
      if (i < length) yield separator;
    }
  }
}