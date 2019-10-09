// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Thanks for checking out Flutter!
// Like what you see? Tweet us @FlutterDev

import 'dart:io';

import 'package:flutter/material.dart';

import 'gallery/app.dart';

import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride, kIsWeb;

void main() {
  _setTargetPlatformForDesktop();
  runApp(const GalleryApp());
}

void _setTargetPlatformForDesktop() {
  TargetPlatform targetPlatform;
  if (!kIsWeb) {
    if (Platform.isMacOS) {
      targetPlatform = TargetPlatform.iOS;
    } else if (Platform.isLinux || Platform.isWindows) {
      targetPlatform = TargetPlatform.android;
    }
    if (targetPlatform != null) {
      debugDefaultTargetPlatformOverride = targetPlatform;
    }
  }
}
