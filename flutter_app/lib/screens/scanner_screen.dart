import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:ui';
import '../models/exam.dart';
import '../core/app_colors.dart';
import 'scan_success_screen.dart';

class ScannerScreen extends StatefulWidget {
  final Exam exam;

  const ScannerScreen({super.key, required this.exam});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with SingleTickerProviderStateMixin {
  CameraController? _controller;
  bool _isFlashOn = false;
  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    
    _scanLineAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      ),
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  void _toggleFlash() {
    if (_controller == null) return;
    setState(() {
      _isFlashOn = !_isFlashOn;
      _controller!.setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
    });
  }

  Future<void> _captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final image = await _controller!.takePicture();
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScanSuccessScreen(
            exam: widget.exam,
            imagePath: image.path,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error capturing image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Feed
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),

          // Top Controls
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildRoundButton(
                    icon: Icons.close,
                    onTap: () => Navigator.pop(context),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Text(
                        widget.exam.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  _buildRoundButton(
                    icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                    onTap: _toggleFlash,
                  ),
                ],
              ),
            ),
          ),

          // Scanner Overlay
          _buildScannerOverlay(),

          // Bottom Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(bottom: 48, left: 32, right: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildRoundButton(
                    icon: Icons.image_outlined,
                    onTap: () {},
                    color: Colors.white.withOpacity(0.1),
                    size: 48,
                  ),
                  GestureDetector(
                    onTap: _captureImage,
                    child: Container(
                      width: 72,
                      height: 72,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  _buildRoundButton(
                    icon: Icons.grid_view_rounded,
                    onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
                    color: AppColors.primary.withOpacity(0.2),
                    iconColor: AppColors.primary,
                    size: 48,
                    borderRadius: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = 40,
    Color? color,
    Color iconColor = Colors.white,
    double borderRadius = 100,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color ?? Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(borderRadius),
              border: color == null ? Border.all(color: Colors.white.withOpacity(0.1)) : null,
            ),
            child: Icon(icon, color: iconColor, size: size * 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return AnimatedBuilder(
      animation: _scanLineAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: ScannerOverlayPainter(),
              ),
            ),
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                height: MediaQuery.of(context).size.width * 1.15,
                child: Stack(
                  children: [
                    Positioned(
                      top: (MediaQuery.of(context).size.width * 1.15) * _scanLineAnimation.value,
                      left: 10,
                      right: 10,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.primary.withOpacity(0.8),
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.5),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Positioned(
                      bottom: -40,
                      left: 0,
                      right: 0,
                      child: Text(
                        'Optik formu çerçeve içine hizalayın',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scanWidth = size.width * 0.85;
    final scanHeight = size.width * 1.15;
    final left = (size.width - scanWidth) / 2;
    final top = (size.height - scanHeight) / 2;
    final rect = Rect.fromLTWH(left, top, scanWidth, scanHeight);

    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(24))),
      ),
      backgroundPaint,
    );

    final bracketPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const bracketSize = 40.0;
    const radius = 24.0;

    canvas.drawPath(
      Path()
        ..moveTo(left, top + bracketSize)
        ..lineTo(left, top + radius)
        ..arcToPoint(Offset(left + radius, top), radius: const Radius.circular(radius))
        ..lineTo(left + bracketSize, top),
      bracketPaint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(left + scanWidth - bracketSize, top)
        ..lineTo(left + scanWidth - radius, top)
        ..arcToPoint(Offset(left + scanWidth, top + radius), radius: const Radius.circular(radius))
        ..lineTo(left + scanWidth, top + bracketSize),
      bracketPaint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(left, top + scanHeight - bracketSize)
        ..lineTo(left, top + scanHeight - radius)
        ..arcToPoint(Offset(left + radius, top + scanHeight), radius: const Radius.circular(radius))
        ..lineTo(left + bracketSize, top + scanHeight),
      bracketPaint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(left + scanWidth - bracketSize, top + scanHeight)
        ..lineTo(left + scanWidth - radius, top + scanHeight)
        ..arcToPoint(Offset(left + scanWidth, top + scanHeight - radius), radius: const Radius.circular(radius))
        ..lineTo(left + scanWidth, top + scanHeight - bracketSize),
      bracketPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
