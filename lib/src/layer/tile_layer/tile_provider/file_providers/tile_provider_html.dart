import 'package:flutter/widgets.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_coordinates.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_layer.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/base_tile_provider.dart';
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network_providers/tile_provider_html.dart';

/// [TileProvider] to fetch tiles from the local filesystem (not asset store)
///
/// This web implmentation does not support reading from the local filesystem,
/// and therefore resorts to the web implementation of [NetworkTileProvider].
class FileTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      NetworkTileProvider().getImage(coordinates, options);
}
