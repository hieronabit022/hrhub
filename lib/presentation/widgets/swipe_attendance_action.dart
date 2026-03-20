import 'dart:ui';

import 'package:flutter/material.dart';

class SwipeAttendanceAction extends StatefulWidget {
  final bool checkedIn;
  final Future<void> Function() onClockIn;
  final Future<void> Function() onClockOut;
  final Future<bool> Function()? isWithinOfficeRadius;

  const SwipeAttendanceAction({
    super.key,
    required this.checkedIn,
    required this.onClockIn,
    required this.onClockOut,
    this.isWithinOfficeRadius,
  });

  @override
  State<SwipeAttendanceAction> createState() => _SwipeAttendanceActionState();
}

class _SwipeAttendanceActionState extends State<SwipeAttendanceAction> {
  double _drag = 0;
  bool _submitting = false;

  double _baseOffset(double halfTravel) => widget.checkedIn ? halfTravel : -halfTravel;

  Future<void> _showStatusDialog({
    required String title,
    required String message,
    required bool success,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.error_rounded,
              color: success ? const Color(0xFF16A34A) : Colors.redAccent,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showRemoteWorkDialog() async {
    if (!mounted) return null;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose attendance type'),
        content: const Text(
          'Office area was not detected. Please choose your attendance type before clocking in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'Business Trip'),
            child: const Text('Business Trip'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'WFA'),
            child: const Text('WFA'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseGradient = widget.checkedIn
        ? const [Color(0xFF2C3147), Color(0xFF4A4F66)]
        : const [Color(0xFF4A4F66), Color(0xFFF2B31A)];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const knobWidth = 96.0;
        const knobHeight = 48.0;
        const horizontalPadding = 6.0;
        final travel = (width - knobWidth - (horizontalPadding * 2)).clamp(1.0, double.infinity);
        final minLeft = horizontalPadding;
        final maxLeft = width - knobWidth - horizontalPadding;
        final centerLeft = (width - knobWidth) / 2;
        final halfTravel = travel / 2;
        final baseOffset = _baseOffset(halfTravel);
        final effectiveOffset = (baseOffset + _drag).clamp(-halfTravel, halfTravel);
        final knobLeft = (centerLeft + effectiveOffset).clamp(minLeft, maxLeft);
        final normalized = (effectiveOffset / halfTravel).clamp(-1.0, 1.0);

        Future<void> submit(bool clockIn) async {
          if (_submitting) return;
          if (clockIn == widget.checkedIn) {
            setState(() => _drag = 0);
            await _showStatusDialog(
              title: clockIn ? 'Clock In Failed' : 'Clock Out Failed',
              message: clockIn
                  ? 'You are already clocked in.'
                  : 'Please clock in before clocking out.',
              success: false,
            );
            return;
          }

          setState(() => _submitting = true);
          String? attendanceType;
          try {
            if (clockIn && widget.isWithinOfficeRadius != null) {
              final inOffice = await widget.isWithinOfficeRadius!.call();
              if (!inOffice) {
                attendanceType = await _showRemoteWorkDialog();
                if (attendanceType == null) {
                  if (mounted) {
                    setState(() {
                      _drag = 0;
                      _submitting = false;
                    });
                  }
                  return;
                }
              }
            }

            if (clockIn) {
              await widget.onClockIn();
            } else {
              await widget.onClockOut();
            }

            final message = clockIn
                ? (attendanceType == null
                    ? 'Your clock in was recorded successfully.'
                    : 'Your clock in was recorded as $attendanceType.')
                : 'Your clock out was recorded successfully.';
            await _showStatusDialog(
              title: clockIn ? 'Clock In Success' : 'Clock Out Success',
              message: message,
              success: true,
            );
          } catch (_) {
            await _showStatusDialog(
              title: clockIn ? 'Clock In Failed' : 'Clock Out Failed',
              message: 'Something went wrong while saving your attendance. Please try again.',
              success: false,
            );
          } finally {
            if (mounted) {
              setState(() {
                _drag = 0;
                _submitting = false;
              });
            }
          }
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: baseGradient,
            ),
            boxShadow: [
              BoxShadow(
                color: baseGradient.last.withValues(alpha: 0.24),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 24,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.18),
                          Colors.white.withValues(alpha: 0.02),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: widget.checkedIn ? 22 : 122,
                    right: widget.checkedIn ? 122 : 22,
                  ),
                  child: Align(
                    alignment: widget.checkedIn ? Alignment.centerLeft : Alignment.centerRight,
                    child: Text(
                      widget.checkedIn ? 'Clock Out' : 'Clock In',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: knobLeft,
                top: 6,
                child: GestureDetector(
                  onHorizontalDragUpdate: _submitting
                      ? null
                      : (details) {
                          setState(() {
                            _drag = (_drag + details.delta.dx).clamp(-travel, travel);
                          });
                        },
                  onHorizontalDragEnd: _submitting
                      ? null
                      : (_) async {
                          if (normalized >= 0.7) {
                            await submit(true);
                            return;
                          }
                          if (normalized <= -0.7) {
                            await submit(false);
                            return;
                          }
                          setState(() => _drag = 0);
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    curve: Curves.easeOut,
                    width: knobWidth,
                    height: knobHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                      border: Border.all(
                        color: baseGradient.first.withValues(alpha: 0.22),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                        child: Center(
                          child: _submitting
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.3,
                                    valueColor: AlwaysStoppedAnimation<Color>(baseGradient.first),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _drag == 0
                                          ? (widget.checkedIn
                                              ? Icons.arrow_back_rounded
                                              : Icons.arrow_forward_rounded)
                                          : (normalized >= 0
                                              ? Icons.arrow_forward_rounded
                                              : Icons.arrow_back_rounded),
                                      color: baseGradient.first,
                                      size: 21,
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.fingerprint_rounded,
                                      color: baseGradient.first,
                                      size: 20,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
