import 'package:flutter/material.dart';

Future<void> showSuccessDialog(
  BuildContext context, {
  required String title,
  required String message,
  String buttonText = 'OK',
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(title)),
        ],
      ),
      content: Text(message),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(buttonText),
        ),
      ],
    ),
  );
}

Future<void> showErrorDialog(
  BuildContext context, {
  required String title,
  required String message,
  String buttonText = 'Tutup',
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.error_rounded, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(child: Text(title)),
        ],
      ),
      content: Text(message),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: Text(buttonText),
        ),
      ],
    ),
  );
}

Future<bool> showRetryDialog(
  BuildContext context, {
  required String title,
  required String message,
  String retryText = 'Coba lagi',
  String cancelText = 'Batal',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.refresh_rounded, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(child: Text(title)),
        ],
      ),
      content: Text(message),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelText),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(retryText),
        ),
      ],
    ),
  );
  return result ?? false;
}
