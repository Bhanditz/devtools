// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../ui/elements.dart';
import '../ui/fake_flutter/dart_ui/dart_ui.dart';
import '../ui/flutter_html_shim.dart';
import 'timeline_protocol.dart';

// TODO(kenzie): implement zoom functionality.

// Switch this flag to true to dump the frame event trace to console.
bool _debugEventTrace = false;

// Amber 50 color palette from
// https://material.io/design/color/the-color-system.html#tools-for-picking-colors.
const cpuColorPalette = [
  Color(0xFFFFECB3),
  Color(0xFFFFE082),
  Color(0xFFFFD54F),
  Color(0xFFFFCA28),
];

// Light Green 50 color palette from
// https://material.io/design/color/the-color-system.html#tools-for-picking-colors.
const gpuColorPalette = [
  Color(0xFFDCEDC8),
  Color(0xFFC5E1A5),
  Color(0xFFAED581),
  Color(0xFF9CCC65),
];

class FrameFlameChart extends CoreElement {
  FrameFlameChart() : super('div') {
    flex();
    clazz('frame-timeline');
  }

  TimelineFrame frame;
  CoreElement sectionTitles;
  CoreElement flameChart;
  int _cpuColorOffset = 0;
  int _gpuColorOffset = 0;

  Color nextCpuColor() {
    final color = cpuColorPalette[_cpuColorOffset % cpuColorPalette.length];
    _cpuColorOffset++;
    return color;
  }

  Color nextGpuColor() {
    final color = gpuColorPalette[_gpuColorOffset % gpuColorPalette.length];
    _gpuColorOffset++;
    return color;
  }

  void updateFrameData(TimelineFrame frame) {
    this.frame = frame;

    clear();

    if (_debugEventTrace && frame != null) {
      final StringBuffer buf = new StringBuffer();
      buf.writeln('CPU for frame ${frame.id}:');
      frame.cpuEventFlow.format(buf, '  ');
      buf.writeln('GPU for frame ${frame.id}:');
      frame.gpuEventFlow.format(buf, '  ');
      print(buf.toString());
    }

    if (frame != null) {
      _render(frame);
    }
  }

  void _render(TimelineFrame frame) {
    const int leftIndent = 80;
    const int rowHeight = 25;

    // TODO(kenzie): re-write this scale logic.
    const double microsPerFrame = 1000 * 1000 / 60.0;
    const double pxPerMicro = microsPerFrame / 1000.0;

    int row = 0;

    final int microsAdjust = frame.startTime;

    int maxRow = 0;

    void drawRecursively(TimelineEvent event, int row) {
      final double start = (event.startTime - microsAdjust) / pxPerMicro;
      final double end =
          (event.startTime - microsAdjust + event.duration) / pxPerMicro;

      _drawFlameChartItem(
        event,
        leftIndent + start.round(),
        (end - start).round(),
        row * rowHeight,
      );

      if (row > maxRow) {
        maxRow = row;
      }

      for (TimelineEvent child in event.children) {
        drawRecursively(child, row + 1);
      }
    }

    void drawCpuEvents() {
      final int sectionTop = row * rowHeight;
      final CoreElement sectionTitle = div(text: 'CPU', c: 'flame-chart-item');
      sectionTitle.element.style.background = colorToCss(cpuColorPalette.last);
      sectionTitle.element.style.left = '0';
      sectionTitle.element.style.top = '${sectionTop}px';
      add(sectionTitle);

      maxRow = row;

      drawRecursively(frame.cpuEventFlow, row);

      row = maxRow;

      row++;
    }

    void drawGpuEvents() {
      final int sectionTop = row * rowHeight;
      final CoreElement sectionTitle = div(text: 'GPU', c: 'flame-chart-item');
      sectionTitle.element.style.background = colorToCss(gpuColorPalette.last);
      sectionTitle.element.style.left = '0';
      sectionTitle.element.style.top = '${sectionTop}px';
      add(sectionTitle);

      maxRow = row;

      drawRecursively(frame.gpuEventFlow, row);

      row = maxRow;

      row++;
    }

    drawCpuEvents();

    // TODO(kenzie): improve this by adding a spacer div instead of just
    // increasing the row. Do this once each section is in its own container.
    // Add an additional row for spacing between CPU and GPU events.
    row++;

    drawGpuEvents();
  }

  // TODO(kenzie): re-assess this drawing logic.
  void _drawFlameChartItem(TimelineEvent event, int left, int width, int top) {
    final CoreElement item = div(text: event.name, c: 'flame-chart-item');
    item.element.style.background = event.isCpuEvent
        ? colorToCss(nextCpuColor())
        : colorToCss(nextGpuColor());
    item.element.style.left = '${left}px';
    if (width != null) {
      item.element.style.width = '${width}px';
    }
    item.element.style.top = '${top}px';
    add(item);
  }
}
