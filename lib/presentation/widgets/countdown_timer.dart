import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/theme.dart';

class CountdownTimer extends StatefulWidget {
  final DateTime targetDate;

  const CountdownTimer({super.key, required this.targetDate});

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Timer _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateTimeLeft();
    });
  }

  void _calculateTimeLeft() {
    final now = DateTime.now();
    final diff = widget.targetDate.difference(now);
    if (mounted) {
      setState(() {
        _timeLeft = diff.isNegative ? Duration.zero : diff;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_timeLeft.inSeconds == 0) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final days = _timeLeft.inDays;
    final hours = _timeLeft.inHours.remainder(24);
    final minutes = _timeLeft.inMinutes.remainder(60);
    final seconds = _timeLeft.inSeconds.remainder(60);

    return Container(
      decoration: AppTheme.glassBoxDecoration(context: context),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.hourglass_empty_rounded,
                color: Theme.of(context).colorScheme.secondary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'COUNTDOWN TO KICKOFF',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTimeItem(days, 'Days'),
              _buildDivider(),
              _buildTimeItem(hours, 'Hours'),
              _buildDivider(),
              _buildTimeItem(minutes, 'Mins'),
              _buildDivider(),
              _buildTimeItem(seconds, 'Secs'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeItem(int val, String label) {
    return Column(
      children: [
        Text(
          val.toString().padLeft(2, '0'),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return const Text(
      ':',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w900,
        color: Colors.grey,
      ),
    );
  }
}
