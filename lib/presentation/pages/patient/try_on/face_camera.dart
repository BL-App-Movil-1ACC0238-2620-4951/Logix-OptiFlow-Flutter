import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'package:logix_optiflow/presentation/pages/patient/try_on/try_on_glasses.dart';

/// Cámara frontal con ML Kit Face Detection (sin internet). Llama a [onEyes] en cada cuadro con
/// los ojos del rostro principal, o con null si no hay rostro. Las coordenadas ya vienen en la
/// vista (escaladas y en espejo como la vista previa), así que se pueden dibujar encima tal cual.
/// Sin permiso o sin cámara llama a [onUnavailable], con true si el dispositivo no tiene cámara
/// (por ejemplo, el simulador de iOS).
class FaceCamera extends StatefulWidget {
  const FaceCamera({super.key, required this.onEyes, required this.onUnavailable});

  final ValueChanged<EyePositions?> onEyes;
  final ValueChanged<bool> onUnavailable;

  @override
  State<FaceCamera> createState() => _FaceCameraState();
}

class _FaceCameraState extends State<FaceCamera> with WidgetsBindingObserver {
  final _detector = FaceDetector(options: FaceDetectorOptions(enableLandmarks: true, performanceMode: FaceDetectorMode.fast));
  CameraController? _controller;
  bool _busy = false;
  Size _view = Size.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // La cámara se apaga cuando la app deja de verse y vuelve al regresar. No se usa "inactive"
    // porque el diálogo de permiso también la pone así y cortaría la cámara mientras se abre.
    if (state == AppLifecycleState.paused) {
      _stop();
    } else if (state == AppLifecycleState.resumed && _controller == null) {
      _start();
    }
  }

  Future<void> _start() async {
    var noCamera = false;
    try {
      final cameras = await availableCameras();
      final front = cameras.where((c) => c.lensDirection == CameraLensDirection.front).firstOrNull ?? cameras.firstOrNull;
      if (front == null) {
        noCamera = true;
        throw CameraException('NoCamera', null);
      }
      final controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.nv21,
      );
      _controller = controller;
      await controller.initialize();
      if (!mounted || _controller != controller) return;
      await controller.startImageStream((image) => _analyze(image, front));
      setState(() {});
    } catch (_) {
      // Sin permiso de cámara (o sin cámara): la pantalla ofrece pedirlo de nuevo.
      await _stop();
      if (mounted) widget.onUnavailable(noCamera);
    }
  }

  Future<void> _stop() async {
    final controller = _controller;
    _controller = null;
    if (mounted) setState(() {});
    await controller?.dispose();
  }

  Future<void> _analyze(CameraImage image, CameraDescription camera) async {
    if (_busy) return;
    _busy = true;
    try {
      final rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation) ?? InputImageRotation.rotation0deg;
      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null || image.planes.isEmpty) return;
      final input = InputImage.fromBytes(
        bytes: image.planes.first.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
      final faces = await _detector.processImage(input);
      if (!mounted) return;
      final face = faces.isEmpty ? null : faces.reduce((a, b) => a.boundingBox.width >= b.boundingBox.width ? a : b);
      final left = face?.landmarks[FaceLandmarkType.leftEye]?.position;
      final right = face?.landmarks[FaceLandmarkType.rightEye]?.position;
      if (left == null || right == null) {
        widget.onEyes(null);
        return;
      }
      // ML Kit da los puntos en la imagen ya derecha; la vista previa la llena recortada y en espejo.
      final sideways = rotation == InputImageRotation.rotation90deg || rotation == InputImageRotation.rotation270deg;
      final imageW = sideways ? image.height.toDouble() : image.width.toDouble();
      final imageH = sideways ? image.width.toDouble() : image.height.toDouble();
      final mirror = camera.lensDirection == CameraLensDirection.front;
      Offset toView(math.Point<int> p) {
        final scale = _view.width / imageW > _view.height / imageH ? _view.width / imageW : _view.height / imageH;
        final dx = (_view.width - imageW * scale) / 2;
        final dy = (_view.height - imageH * scale) / 2;
        final x = mirror ? imageW - p.x : p.x.toDouble();
        return Offset(dx + x * scale, dy + p.y * scale);
      }

      widget.onEyes(EyePositions(toView(left), toView(right), face!.headEulerAngleY ?? 0));
    } catch (_) {
      // Un cuadro que no se pudo leer se salta.
    } finally {
      _busy = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stop();
    _detector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return LayoutBuilder(
      builder: (context, constraints) {
        _view = constraints.biggest;
        final preview = controller?.value.previewSize;
        if (controller == null || !controller.value.isInitialized || preview == null) return const SizedBox.expand();
        // La vista previa viene acostada: se para y se recorta para llenar el espacio.
        return ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(width: preview.height, height: preview.width, child: CameraPreview(controller)),
          ),
        );
      },
    );
  }
}
