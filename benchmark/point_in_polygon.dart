import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_map/src/misc/point_in_polygon.dart';
import 'package:logger/logger.dart';

class NoFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => true;
}

typedef Result = ({
  String name,
  Duration duration,
});

Future<Result> timedRun(String name, dynamic Function() body) async {
  Logger().i('running $name...');
  final watch = Stopwatch()..start();
  await body();
  watch.stop();

  return (name: name, duration: watch.elapsed);
}

// NOTE: to have a more prod like comparison, run with:
//     $ dart compile exe benchmark/crs.dart && ./benchmark/crs.exe
//
// If you run in JIT mode, the resulting execution times will be a lot more similar.
Future<void> main() async {
  Logger.level = Level.all;
  Logger.defaultFilter = NoFilter.new;
  Logger.defaultPrinter = SimplePrinter.new;

  final results = <Result>[];
  const N = 3000000;
  const points = 1000;

  results.add(await timedRun('In circle', () {
    final polygon = List.generate(points, (i) {
      final angle = math.pi * 2 / points * i;
      return Offset(math.cos(angle), math.sin(angle));
    });

    const point = math.Point(0, 0);

    bool yesPlease = true;
    for (int i = 0; i < N; ++i) {
      yesPlease = yesPlease && pointInPolygon(point, polygon);
    }

    assert(yesPlease, 'should be in circle');
    return yesPlease;
  }));

  results.add(await timedRun('Not in circle', () {
    final polygon = List.generate(points, (i) {
      final angle = math.pi * 2 / points * i;
      return Offset(math.cos(angle), math.sin(angle));
    });

    const point = math.Point(4, 4);

    bool noSir = false;
    for (int i = 0; i < N; ++i) {
      noSir = noSir || pointInPolygon(point, polygon);
    }

    assert(!noSir, 'should not be in circle');
    return noSir;
  }));

  Logger().i('Results:\n${results.map((r) => r.toString()).join('\n')}');
}
