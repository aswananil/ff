import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:proj4dart/proj4dart.dart' as proj4;

import '../widgets/drawer.dart';

class CustomCrsPage extends StatelessWidget {
  static const String route = 'custom_crs';

  /// Define projections
  /// EPSG:4326 is a predefined projection ships with proj4dart
  /// EPSG:3413 is a user-defined projection from a valid Proj4 definition string
  static final proj4.Projection epsg4326 = proj4.Projection('EPSG:4326');
  static final proj4.Projection epsg3413 = proj4.Projection.add('EPSG:3413',
      '+proj=stere +lat_0=90 +lat_ts=70 +lon_0=-45 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs');
  static final List<double> resolutions = [
    4096,
    2048,
    1024,
    512,
    256,
    128,
    64,
    32,
    16,
    8,
    4,
    2,
    1,
    0.5,
    0.25,
    0.125
  ];
  final double maxZoom = (resolutions.length - 1).toDouble();

  // Define the CRS
  final Proj4Crs epsg3413CRS = Proj4Crs.fromFactory(
      code: 'EPSG:3413', proj4Projection: epsg3413, resolutions: resolutions);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Custom CRS (EPSG:3413)')),
      drawer: buildDrawer(context, route),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child:
                  Text('This is a map that is showing (64.75777, -18.46302).'),
            ),
            Flexible(
              child: FlutterMap(
                options: MapOptions(
                  // Set the default CRS
                  crs: epsg3413CRS,
                  center: LatLng(64.75777213671648, -18.463028416855547),
                  zoom: 1.0,
                  maxZoom: maxZoom,
                ),
                layers: [
                  TileLayerOptions(
                    opacity: 1.0,
                    backgroundColor: Colors.white.withOpacity(0),
                    wmsOptions: WMSTileLayerOptions(
                      // Set the WMS layer's CRS
                      crs: epsg3413CRS,
                      transparent: true,
                      format: 'image/jpeg',
                      baseUrl:
                          'https://www.gebco.net/data_and_products/gebco_web_services/north_polar_view_wms/mapserv?',
                      layers: ['gebco_north_polar_view'],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
