import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../webviewtube.dart';

/// {@template progress_bar}
/// A widget to display the progress bar of the video.
///
/// Colors of the progress bar can be configured with [ProgressBarColors].
/// {@endtemplate}
class ProgressBar extends StatefulWidget {
  /// {@macro progress_bar}
  const ProgressBar({super.key, this.colors});

  /// Defines colors for the [ProgressBar]. If null,
  /// `Theme.of(context).colorScheme.secondary` is used.
  final ProgressBarColors? colors;

  @override
  State<ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<ProgressBar> {
  late ProgressBarColors colors;
  Duration _position = Duration.zero;
  bool _touchDown = false;
  bool _positionChanged = false;

  @override
  void didChangeDependencies() {
    colors = widget.colors ??
        ProgressBarColors(
            backgroundColor: Theme.of(context).colorScheme.secondary.withAlpha(38),
            playedColor: Theme.of(context).colorScheme.secondary,
            bufferedColor: Colors.white70,
            handleColor: Theme.of(context).colorScheme.secondary);
    super.didChangeDependencies();
  }

  Duration _getRelativePosition(Offset globalPosition) {
    final box = context.findRenderObject() as RenderBox;
    var touchPoint = box.globalToLocal(globalPosition);
    if (touchPoint.dx <= 0) {
      touchPoint = Offset(0, touchPoint.dy);
    }
    if (touchPoint.dx >= context.size!.width) {
      touchPoint = Offset(context.size!.width, touchPoint.dy);
    }

    final relative = touchPoint.dx / box.size.width;
    final position = context.read<WebviewtubeController>().value.videoMetadata.duration * relative;

    return position;
  }

  void _onHorizontalDragDown(DragDownDetails details) {
    setState(() {
      _touchDown = true;
      _position = _getRelativePosition(details.globalPosition);
      _positionChanged = true;
    });
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _position = _getRelativePosition(details.globalPosition);
      _positionChanged = true;
    });
  }

  void _onHorizontalDragEnd() {
    setState(() {
      _touchDown = false;
      _positionChanged = false;
    });
    context.read<WebviewtubeController>().seekTo(_position, allowSeekAhead: true);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragDown: _onHorizontalDragDown,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: (_) => _onHorizontalDragEnd(),
      onHorizontalDragCancel: _onHorizontalDragEnd,
      child: Consumer<WebviewtubeController>(builder: (context, controller, _) {
        var playedRatio = 0.0;
        final durationMs = controller.value.videoMetadata.duration.inMilliseconds;
        if (!durationMs.isNaN && durationMs != 0) {
          double val;
          if (_positionChanged) {
            val = _position.inMilliseconds / durationMs;
          } else {
            val = controller.value.position.inMilliseconds / durationMs;
          }

          playedRatio = double.parse(val.toStringAsFixed(3));
        }

        return CustomPaint(
          size: Size(MediaQuery.of(context).size.width, 14),
          painter: _ProgressBarPainter(
            progressWidth: 4.0,
            handleRadius: 7.0,
            playedRatio: playedRatio,
            bufferedRatio: controller.value.buffered,
            colors: colors,
            touchDown: _touchDown,
          ),
        );
      }),
    );
  }
}

class _ProgressBarPainter extends CustomPainter {
  _ProgressBarPainter({
    required this.progressWidth,
    required this.handleRadius,
    required this.playedRatio,
    required this.bufferedRatio,
    required this.touchDown,
    required this.colors,
  });

  final double progressWidth;
  final double handleRadius;
  final double playedRatio;
  final double bufferedRatio;
  final bool touchDown;
  final ProgressBarColors colors;

  @override
  bool shouldRepaint(_ProgressBarPainter oldDelegate) {
    return playedRatio != oldDelegate.playedRatio ||
        bufferedRatio != oldDelegate.bufferedRatio ||
        touchDown != oldDelegate.touchDown;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.square
      ..strokeWidth = progressWidth;
    final handlePaint = Paint()..isAntiAlias = true;

    final centerY = size.height / 2.0;
    final barLength = size.width - handleRadius * 2.0;

    final startPoint = Offset(handleRadius, centerY);
    final endPoint = Offset(size.width - handleRadius, centerY);
    final progressPoint = Offset(
      barLength * playedRatio + handleRadius,
      centerY,
    );
    final secondProgressPoint = Offset(
      barLength * bufferedRatio + handleRadius,
      centerY,
    );

    paint.color = colors.backgroundColor;
    canvas.drawLine(startPoint, endPoint, paint);

    paint.color = colors.bufferedColor;
    canvas.drawLine(startPoint, secondProgressPoint, paint);

    paint.color = colors.playedColor;
    canvas.drawLine(startPoint, progressPoint, paint);

    handlePaint.color = Colors.transparent;
    canvas.drawCircle(progressPoint, centerY, handlePaint);

    if (touchDown) {
      handlePaint.color = colors.handleColor.withAlpha(40);
      canvas.drawCircle(progressPoint, handleRadius * 3, handlePaint);
    }

    handlePaint.color = colors.handleColor;
    canvas.drawCircle(progressPoint, handleRadius, handlePaint);
  }
}
