---
id: marker-layer
sidebar_position: 3
---

# Marker Layer

You can add markers to maps to display specific points to users using `MarkerLayerOptions()`.

```dart
FlutterMap(
    options: MapOptions(),
    layers: [
        MarkerLayerOptions(
            markers: [
                Marker(
                  point: LatLng(30, 40),
                  width: 80,
                  height: 80,
                  builder: (context) => FlutterLogo(),
                ),
            ],
        ),
    ],
),
```

:::caution Performance Issues
Excessive use of markers or use of complex markers will create performance issues and lag/'jank' as the user interacts with the map. See [Performance Issues](/examples-and-errors/common-errors#performance-issues) for more information.

If you need to use a large number of markers, an existing [community maintained plugin (`flutter_map_marker_cluster`)](https://github.com/lpongetti/flutter_map_marker_cluster) might help.
:::

## Markers (`markers:`)

As you can see `MarkerLayerOptions()` accepts list of Markers which determines render widget, position and transformation details like size and rotation.

| Property          | Type                 | Defaults               | Description                                                    |
| :---------------- | :------------------- | :--------------------- | :------------------------------------------------------------- |
| `point`           | `LatLng`             | required               | Marker position on map                                         |
| `builder`         | `WidgetBuilder`      | required               | Builder used to render marker                                  |
| `width`           | `double`             | `30`                   | Marker width                                                   |
| `height`          | `double`             | `30`                   | Marker height                                                  |
| `rotate`          | `bool?`              | `false`*               | If true, marker will be counter rotated to the map rotation    |
| `rotateOrigin`    | `Offset?`            |                        | The origin of the marker in which to apply the matrix          |
| `rotateAlignment` | `AlignmentGeometry?` |                        | The alignment of the origin, relative to the size of the box   |
| `anchorPos`       | `AnchorPos?`         |                        | Point of the marker which will correspond to marker's location |
