// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter_gallery/demo/shrine/model/app_state_model.dart';
import 'package:scoped_model/scoped_model.dart';

import 'package:url_launcher/url_launcher.dart';

import 'demos.dart';
import 'home.dart';
import 'options.dart';
import 'scales.dart';
import 'themes.dart';
import 'updater.dart';

class GalleryApp extends StatefulWidget {
  const GalleryApp({
    Key key,
    this.updateUrlFetcher,
    this.enablePerformanceOverlay = true,
    this.enableRasterCacheImagesCheckerboard = true,
    this.enableOffscreenLayersCheckerboard = true,
    this.onSendFeedback,
    this.testMode = false,
  }) : super(key: key);

  final UpdateUrlFetcher updateUrlFetcher;
  final bool enablePerformanceOverlay;
  final bool enableRasterCacheImagesCheckerboard;
  final bool enableOffscreenLayersCheckerboard;
  final VoidCallback onSendFeedback;
  final bool testMode;

  @override
  _GalleryAppState createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> {
  GalleryOptions _options;
  Timer _timeDilationTimer;
  AppStateModel model;

  Map<String, WidgetBuilder> _buildRoutes() {
    // For a different example of how to set up an application routing table
    // using named routes, consider the example in the Navigator class documentation:
    // https://docs.flutter.io/flutter/widgets/Navigator-class.html
    return Map<String, WidgetBuilder>.fromIterable(
      kAllGalleryDemos,
      key: (dynamic demo) => '${demo.routeName}',
      value: (dynamic demo) => demo.buildRoute,
    );
  }

  @override
  void initState() {
    super.initState();
    _options = GalleryOptions(
      themeMode: ThemeMode.system,
      textScaleFactor: kAllGalleryTextScaleValues[0],
      timeDilation: timeDilation,
      platform: defaultTargetPlatform,
    );
    model = AppStateModel()..loadProducts();
  }

  @override
  void dispose() {
    _timeDilationTimer?.cancel();
    _timeDilationTimer = null;
    super.dispose();
  }

  void _handleOptionsChanged(GalleryOptions newOptions) {
    setState(() {
      if (_options.timeDilation != newOptions.timeDilation) {
        _timeDilationTimer?.cancel();
        _timeDilationTimer = null;
        if (newOptions.timeDilation > 1.0) {
          // We delay the time dilation change long enough that the user can see
          // that UI has started reacting and then we slam on the brakes so that
          // they see that the time is in fact now dilated.
          _timeDilationTimer = Timer(const Duration(milliseconds: 150), () {
            timeDilation = newOptions.timeDilation;
          });
        } else {
          timeDilation = newOptions.timeDilation;
        }
      }

      _options = newOptions;
    });
  }

  Widget _applyTextScaleFactor(Widget child) {
    return Builder(
      builder: (BuildContext context) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: _options.textScaleFactor.scale,
          ),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget home = GalleryHome(
      testMode: widget.testMode,
      optionsPage: GalleryOptionsPage(
        options: _options,
        onOptionsChanged: _handleOptionsChanged,
        onSendFeedback: widget.onSendFeedback ?? () {
          launch('https://github.com/flutter/flutter/issues/new/choose', forceSafariVC: false);
        },
      ),
    );

    if (widget.updateUrlFetcher != null) {
      home = Updater(
        updateUrlFetcher: widget.updateUrlFetcher,
        child: home,
      );
    }

    return ScopedModel<AppStateModel>(
      model: model,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: kLightGalleryTheme.copyWith(platform: _options.platform),
        darkTheme: kDarkGalleryTheme.copyWith(platform: _options.platform),
        themeMode: _options.themeMode,
        title: 'Flutter Gallery',
        color: Colors.grey,
        showPerformanceOverlay: _options.showPerformanceOverlay,
        checkerboardOffscreenLayers: _options.showOffscreenLayersCheckerboard,
        checkerboardRasterCacheImages: _options.showRasterCacheImagesCheckerboard,
        routes: _buildRoutes(),
        builder: (BuildContext context, Widget child) {
          return Directionality(
            textDirection: _options.textDirection,
            child: _applyTextScaleFactor(
              // Specifically use a blank Cupertino theme here and do not transfer
              // over the Material primary color etc except the brightness to
              // showcase standard iOS looks.
              Builder(builder: (BuildContext context) {
                return CupertinoTheme(
                  data: CupertinoThemeData(
                    brightness: Theme.of(context).brightness,
                  ),
                  child: child,
                );
              }),
            ),
          );
        },
        home: home,
      ),
    );
  }
}
