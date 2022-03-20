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
Excessive use of markers or use of complex markers will create performance issues and lag/'jank' as the user interacts with the map. According to [this comment in a PR on this matter](https://github.com/fleaflet/flutter_map/pull/826#issuecomment-820575346): "3.5k [total markers gives] 60fps when <100 [markers] visible, then maybe 45fps when 200 [markers] visible".

You can see the effects of excessive markers on a page in the [example app](/examples-and-errors/master-example), or you can [see the code itself](https://github.com/fleaflet/flutter_map/blob/master/example/lib/pages/many_markers.dart). If you need to use large numbers of markers, an existing [community maintained plugin (`flutter_map_marker_cluster`)](https://github.com/lpongetti/flutter_map_marker_cluster) might help.
:::

## Markers (`markers:`)

As you can see `MarkerLayerOptions()` accepts list of Markers which determines render widget, position and transformation details like size and rotation.

| Property          | Type                 | Description                                                    |
| :---------------- | :------------------- | :------------------------------------------------------------- |
| `point`           | `LatLng`             | Marker position on map                                         |
| `builder`         | `WidgetBuilder`      | Builder used to render market                                  |
| `width`           | `double`             | Marker width                                                   |
| `height`          | `double`             | Marker height                                                  |
| `rotate`          | `bool?`              | If true marker will be counter rotated to the map rotation     |
| `rotateOrigin`    | `Offset?`            | The origin of the marker in which to apply the matrix.         |
| `rotateAlignment` | `AlignmentGeometry?` | The alignment of the origin, relative to the size of the box   |
| `anchorPos`       | `AnchorPos?`         | Point of the marker which will correspond to marker's location |