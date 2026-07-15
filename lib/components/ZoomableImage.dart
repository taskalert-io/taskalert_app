import 'dart:io';

import 'package:flutter/material.dart';

/// A pannable, pinch-zoomable image that fills the available width — the
/// shared preview widget used by every full-size image popup in the app
/// (uploaded proofs, pre-upload picked files, employee/organization
/// photos, profile photo).
///
/// Give it a local [file] or a [networkUrl] (exactly one). Bound its
/// height with a parent `ConstrainedBox`/`SizedBox`; this widget fills
/// whatever box it's given, scales to that width, and lets you pan to see
/// whatever doesn't fit, or pinch to zoom in further for detail.
class ZoomableImage extends StatelessWidget {
  final File? file;
  final String? networkUrl;
  final Color loaderColor;
  final WidgetBuilder? errorBuilder;

  const ZoomableImage({
    super.key,
    this.file,
    this.networkUrl,
    this.loaderColor = const Color(0xFF0A0258),
    this.errorBuilder,
  });

  Widget _fallback(BuildContext context) =>
      errorBuilder?.call(context) ??
      const Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 32,
          color: Color(0xFF9AA0AB),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return InteractiveViewer(
          // `constrained: false` lets the image lay out at its own full
          // (width-fitted) height instead of being squashed to fit inside
          // the viewport, which would clip it down to only the part that
          // happens to fit. Panning then reaches whatever doesn't fit,
          // exactly like a pinch-zoom pan.
          constrained: false,
          minScale: 1,
          maxScale: 5,
          child: SizedBox(
            width: constraints.maxWidth,
            child: file != null
                ? Image.file(
                    file!,
                    width: constraints.maxWidth,
                    fit: BoxFit.fitWidth,
                    errorBuilder: (context, _, __) => _fallback(context),
                  )
                : Image.network(
                    networkUrl ?? '',
                    width: constraints.maxWidth,
                    fit: BoxFit.fitWidth,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return SizedBox(
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: loaderColor,
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, _, __) => _fallback(context),
                  ),
          ),
        );
      },
    );
  }
}
