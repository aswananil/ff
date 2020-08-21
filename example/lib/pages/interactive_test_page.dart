import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

import '../widgets/drawer.dart';

class InteractiveTestPage extends StatefulWidget {
  static const String route = 'interactive_test_page';

  @override
  State createState() {
    // TODO: try out InteractiveTestPageState it is using StreamBuilder for update Events view and using boolean flags for Filter
    return InteractiveTestPageAlternativeState();
  }
}

class InteractiveTestPageState extends State<InteractiveTestPage> {
  MapController mapController;

  bool drag = false;
  bool flingAnimation = false;
  bool pinchMove = true;
  bool pinchZoom = true;
  bool doubleTapZoom = true;
  bool rotate = false;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
  }

  int _collectInteractiveFlags() {
    var flags = InteractiveFlag.none;
    if (drag) {
      flags = flags | InteractiveFlag.drag; // use |= operator
    }
    if (flingAnimation) {
      flags |= InteractiveFlag.flingAnimation;
    }
    if (pinchMove) {
      flags |= InteractiveFlag.pinchMove;
    }
    if (pinchZoom) {
      flags |= InteractiveFlag.pinchZoom;
    }
    if (doubleTapZoom) {
      flags |= InteractiveFlag.doubleTapZoom;
    }
    if (rotate) {
      flags |= InteractiveFlag.rotate;
    }

    return flags;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test out Interactive flags!')),
      drawer: buildDrawer(context, InteractiveTestPage.route),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                MaterialButton(
                  child: Text('Drag'),
                  color: drag ? Colors.greenAccent : Colors.redAccent,
                  onPressed: () {
                    setState(() {
                      drag = !drag;
                    });
                  },
                ),
                MaterialButton(
                  child: Text('Fling'),
                  color: flingAnimation ? Colors.greenAccent : Colors.redAccent,
                  onPressed: () {
                    setState(() {
                      flingAnimation = !flingAnimation;
                    });
                  },
                ),
                MaterialButton(
                  child: Text('Pinch move'),
                  color: pinchMove ? Colors.greenAccent : Colors.redAccent,
                  onPressed: () {
                    setState(() {
                      pinchMove = !pinchMove;
                    });
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                MaterialButton(
                  child: Text('Double tap zoom'),
                  color: doubleTapZoom ? Colors.greenAccent : Colors.redAccent,
                  onPressed: () {
                    setState(() {
                      doubleTapZoom = !doubleTapZoom;
                    });
                  },
                ),
                MaterialButton(
                  child: Text('Rotate'),
                  color: rotate ? Colors.greenAccent : Colors.redAccent,
                  onPressed: () {
                    setState(() {
                      rotate = !rotate;
                    });
                  },
                ),
                MaterialButton(
                  child: Text('Pinch zoom'),
                  color: pinchZoom ? Colors.greenAccent : Colors.redAccent,
                  onPressed: () {
                    setState(() {
                      pinchZoom = !pinchZoom;
                    });
                  },
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Center(
                child: FutureBuilder<Null>(
                  future: mapController.onReady,
                  builder:
                      (BuildContext context, AsyncSnapshot<Null> snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return Text('No MapEvent fired');
                    }

                    return StreamBuilder<MapEvent>(
                      stream: mapController.mapEventStream,
                      builder: (BuildContext context,
                          AsyncSnapshot<MapEvent> snapshot) {
                        if (snapshot.connectionState == ConnectionState.none ||
                            !snapshot.hasData) {
                          return Text('No MapEvent fired');
                        }

                        return Text(
                          'Current event: ${snapshot.data.runtimeType}\nSource: ${snapshot.data.source}',
                          textAlign: TextAlign.center,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            Flexible(
              child: FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  center: LatLng(51.5, -0.09),
                  zoom: 11.0,
                  interactiveFlags: _collectInteractiveFlags(),
                ),
                layers: [
                  TileLayerOptions(
                    urlTemplate:
                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: ['a', 'b', 'c'],
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

class InteractiveTestPageAlternativeState extends State<InteractiveTestPage> {
  MapController mapController;

  // Enable pinchZoom and doubleTapZoomBy by default
  int flags = InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom;

  // Here is the last moveEvent
  MapEvent lastMapEvent;

  StreamSubscription<MapEvent> subscription;

  @override
  void initState() {
    super.initState();
    mapController = MapController();

    mapController.onReady.then((_) {
      // at this point we can listen to [mapEventStream]
      // use stream transformer or anything you want
      subscription = mapController.mapEventStream.listen((MapEvent mapEvent) {
        setState(() {
          // uncomment to filter specific events (hot reload won't take any effect,
          // because this callback is already registered in initState, so after hot reload
          // you should go away another page then come back OR just use hot restart...)
          // if (mapEvent is! MapEventWithMove) {
          lastMapEvent = mapEvent;
          //}
        });
      });
    });
  }

  @override
  void dispose() {
    if (subscription != null) {
      subscription.cancel();
    }

    super.dispose();
  }

  void updateFlags(int flag) {
    if (InteractiveFlag.hasFlag(flags, flag)) {
      // remove flag from flags
      flags &= ~flag;
    } else {
      // add flag to flags
      flags |= flag;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test out Interactive flags!')),
      drawer: buildDrawer(context, InteractiveTestPage.route),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                MaterialButton(
                  child: Text('Drag'),
                  color: InteractiveFlag.hasFlag(flags, InteractiveFlag.drag)
                      ? Colors.greenAccent
                      : Colors.redAccent,
                  onPressed: () {
                    setState(() {
                      updateFlags(InteractiveFlag.drag);
                    });
                  },
                ),
                MaterialButton(
                  child: Text('Fling'),
                  color: InteractiveFlag.hasFlag(
                          flags, InteractiveFlag.flingAnimation)
                      ? Colors.greenAccent
                      : Colors.redAccent,
                  onPressed: () {
                    setState(() {
                      updateFlags(InteractiveFlag.flingAnimation);
                    });
                  },
                ),
                MaterialButton(
                  child: Text('Pinch move'),
                  color:
                      InteractiveFlag.hasFlag(flags, InteractiveFlag.pinchMove)
                          ? Colors.greenAccent
                          : Colors.redAccent,
                  onPressed: () {
                    setState(() {
                      updateFlags(InteractiveFlag.pinchMove);
                    });
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                MaterialButton(
                  child: Text('Double tap zoom'),
                  color: InteractiveFlag.hasFlag(
                          flags, InteractiveFlag.doubleTapZoom)
                      ? Colors.greenAccent
                      : Colors.redAccent,
                  onPressed: () {
                    setState(() {
                      updateFlags(InteractiveFlag.doubleTapZoom);
                    });
                  },
                ),
                MaterialButton(
                  child: Text('Rotate'),
                  color: InteractiveFlag.hasFlag(flags, InteractiveFlag.rotate)
                      ? Colors.greenAccent
                      : Colors.redAccent,
                  onPressed: () {
                    setState(() {
                      updateFlags(InteractiveFlag.rotate);
                    });
                  },
                ),
                MaterialButton(
                  child: Text('Pinch zoom'),
                  color:
                      InteractiveFlag.hasFlag(flags, InteractiveFlag.pinchZoom)
                          ? Colors.greenAccent
                          : Colors.redAccent,
                  onPressed: () {
                    setState(() {
                      updateFlags(InteractiveFlag.pinchZoom);
                    });
                  },
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Center(
                child: Text(
                  lastMapEvent == null
                      ? 'No MapEvent fired'
                      : 'Current event: ${lastMapEvent.runtimeType}\nSource: ${lastMapEvent.source}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Flexible(
              child: FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  center: LatLng(51.5, -0.09),
                  zoom: 11.0,
                  interactiveFlags: flags,
                ),
                layers: [
                  TileLayerOptions(
                    urlTemplate:
                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: ['a', 'b', 'c'],
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
