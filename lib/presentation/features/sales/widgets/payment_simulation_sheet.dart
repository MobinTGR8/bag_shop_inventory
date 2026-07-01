import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Result returned by the payment simulation sheet.
class PaymentSimulationResult {
  final bool success;

  const PaymentSimulationResult({required this.success});
}

/// Shows a payment simulation bottom sheet for the given payment method(s).
///
/// Returns `PaymentSimulationResult` indicating whether all payment methods
/// were processed successfully.
Future<PaymentSimulationResult> showPaymentSimulation({
  required BuildContext context,
  required double totalAmount,
  required String paymentMode,
  Map<String, dynamic>? paymentSplit,
}) {
  return showModalBottomSheet<PaymentSimulationResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (context) => PaymentSimulationSheet(
      totalAmount: totalAmount,
      paymentMode: paymentMode,
      paymentSplit: paymentSplit,
    ),
  ).then((result) => result ?? const PaymentSimulationResult(success: false));
}

// ============================================================================
// Simulation stages for each payment method
// ============================================================================

class _SimulationStage {
  final IconData icon;
  final String label;
  final Color color;
  final Duration duration;

  const _SimulationStage({
    required this.icon,
    required this.label,
    required this.color,
    this.duration = const Duration(milliseconds: 800),
  });
}

List<_SimulationStage> _stagesForCash(double amount) => [
      const _SimulationStage(
        icon: Icons.payments_outlined,
        label: 'Counting cash…',
        color: Color(0xFF10B981),
        duration: Duration(milliseconds: 600),
      ),
      const _SimulationStage(
        icon: Icons.calculate_outlined,
        label: 'Verifying amount…',
        color: Color(0xFF10B981),
        duration: Duration(milliseconds: 500),
      ),
      _SimulationStage(
        icon: Icons.check_circle_outline,
        label: amount > 0
            ? 'Cash received: Tk ${amount.toStringAsFixed(2)}'
            : 'Cash payment complete',
        color: const Color(0xFF10B981),
        duration: const Duration(milliseconds: 400),
      ),
    ];

List<_SimulationStage> _stagesForCard() => [
      const _SimulationStage(
        icon: Icons.credit_card_outlined,
        label: 'Swipe / Tap card…',
        color: Color(0xFF6366F1),
        duration: Duration(milliseconds: 900),
      ),
      const _SimulationStage(
        icon: Icons.radar,
        label: 'Authorizing transaction…',
        color: Color(0xFF6366F1),
        duration: Duration(milliseconds: 1000),
      ),
      const _SimulationStage(
        icon: Icons.check_circle_outline,
        label: 'Card payment approved',
        color: Color(0xFF10B981),
        duration: Duration(milliseconds: 500),
      ),
    ];

List<_SimulationStage> _stagesForUpi() => [
      const _SimulationStage(
        icon: Icons.qr_code_2,
        label: 'Generating QR code…',
        color: Color(0xFF059669),
        duration: Duration(milliseconds: 700),
      ),
      const _SimulationStage(
        icon: Icons.wifi_find,
        label: 'Waiting for payment…',
        color: Color(0xFF059669),
        duration: Duration(milliseconds: 1200),
      ),
      const _SimulationStage(
        icon: Icons.check_circle_outline,
        label: 'UPI payment received',
        color: Color(0xFF10B981),
        duration: Duration(milliseconds: 500),
      ),
    ];

// ============================================================================
// Main sheet widget
// ============================================================================

class PaymentSimulationSheet extends StatefulWidget {
  final double totalAmount;
  final String paymentMode;
  final Map<String, dynamic>? paymentSplit;

  const PaymentSimulationSheet({
    super.key,
    required this.totalAmount,
    required this.paymentMode,
    this.paymentSplit,
  });

  @override
  State<PaymentSimulationSheet> createState() => _PaymentSimulationSheetState();
}

class _PaymentSimulationSheetState extends State<PaymentSimulationSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  bool _isComplete = false;
  int _currentSubStep = 0;
  int _currentSplitIndex = 0;
  String _statusText = '';

  // For split payments
  late List<_SplitPaymentEntry> _splitEntries;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _splitEntries = _buildSplitEntries();

    // Start simulation after a short delay
    Future.delayed(const Duration(milliseconds: 300), _runSimulation);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  List<_SplitPaymentEntry> _buildSplitEntries() {
    if (widget.paymentMode == 'SPLIT' && widget.paymentSplit != null) {
      return widget.paymentSplit!.entries
          .where((e) => (e.value as num).toDouble() > 0)
          .map((e) => _SplitPaymentEntry(
                method: e.key,
                amount: (e.value as num).toDouble(),
              ))
          .toList();
    }
    return [];
  }

  List<_SimulationStage> _getStagesForMethod(String method, {double? cashAmount}) {
    switch (method) {
      case 'CASH':
        return _stagesForCash(cashAmount ?? widget.totalAmount);
      case 'CARD':
        return _stagesForCard();
      case 'UPI':
        return _stagesForUpi();
      default:
        return _stagesForCash(cashAmount ?? widget.totalAmount);
    }
  }

  Future<void> _runSimulation() async {
    HapticFeedback.mediumImpact();

    if (widget.paymentMode == 'SPLIT') {
      await _runSplitSimulation();
    } else {
      await _runSingleSimulation(
        widget.paymentMode,
        widget.totalAmount,
      );
    }
  }

  Future<void> _runSingleSimulation(
      String method, double amount) async {
    final stages = _getStagesForMethod(method, cashAmount: amount);

    for (int i = 0; i < stages.length; i++) {
      if (!mounted) return;
      setState(() {
        _currentSubStep = i;
        _statusText = stages[i].label;
      });
      HapticFeedback.lightImpact();

      await Future.delayed(stages[i].duration);
      if (!mounted) return;
    }

    // Success!
    if (mounted) {
      setState(() => _isComplete = true);
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _runSplitSimulation() async {
    for (int i = 0; i < _splitEntries.length; i++) {
      if (!mounted) return;
      setState(() => _currentSplitIndex = i);

      final entry = _splitEntries[i];
      await _runSingleSimulation(entry.method, entry.amount);
      if (!mounted) return;

      if (i < _splitEntries.length - 1) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }

    // All split payments done
    if (mounted) {
      setState(() => _isComplete = true);
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: 24 + bottomInset,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: scheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Text(
              widget.paymentMode == 'SPLIT'
                  ? 'Processing Split Payment'
                  : 'Processing Payment',
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              widget.paymentMode == 'SPLIT'
                  ? 'Total: Tk ${widget.totalAmount.toStringAsFixed(2)}'
                  : '${_methodLabel(widget.paymentMode)} • Tk ${widget.totalAmount.toStringAsFixed(2)}',
              style: tt.bodyMedium?.copyWith(
                color: scheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),

            // Split payment progress (only shown for SPLIT mode)
            if (widget.paymentMode == 'SPLIT' && _splitEntries.isNotEmpty) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    for (int i = 0; i < _splitEntries.length; i++) ...[
                      if (i > 0)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: i <= _currentSplitIndex
                                ? const Color(0xFF10B981)
                                : scheme.outline.withOpacity(0.2),
                          ),
                        ),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < _currentSplitIndex || _isComplete
                              ? const Color(0xFF10B981)
                              : i == _currentSplitIndex
                                  ? const Color(0xFF6366F1)
                                  : scheme.outline.withOpacity(0.15),
                        ),
                        child: Center(
                          child: i < _currentSplitIndex || _isComplete
                              ? const Icon(Icons.check,
                                  size: 16, color: Colors.white)
                              : Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    color: i == _currentSplitIndex
                                        ? Colors.white
                                        : scheme.onSurface.withOpacity(0.4),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_currentSplitIndex < _splitEntries.length)
                Text(
                  '${_methodLabel(_splitEntries[_currentSplitIndex].method)} • Tk ${_splitEntries[_currentSplitIndex].amount.toStringAsFixed(2)}',
                  style: tt.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              const SizedBox(height: 12),
            ],

            // Animated simulation stage card
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isComplete ? 1.0 : _pulseAnim.value,
                  child: child,
                );
              },
              child: _buildStageCard(scheme, tt),
            ),

            const SizedBox(height: 20),

            // Status text
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _isComplete
                    ? '✅ Payment successful!'
                    : _statusText,
                key: ValueKey('${_currentSubStep}_$_currentSplitIndex'),
                textAlign: TextAlign.center,
                style: tt.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _isComplete
                      ? const Color(0xFF10B981)
                      : scheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),

            // Done button
            if (_isComplete) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop(
                      const PaymentSimulationResult(success: true),
                    );
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: const Text(
                    'Complete Sale',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStageCard(ColorScheme scheme, TextTheme tt) {
    if (_isComplete) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF10B981).withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded,
                  size: 40, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              widget.paymentMode == 'SPLIT'
                  ? 'All payments completed!'
                  : 'Payment received!',
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
      );
    }

    // Determine current stage and icon
    final currentMethod = widget.paymentMode == 'SPLIT' &&
            _currentSplitIndex < _splitEntries.length
        ? _splitEntries[_currentSplitIndex].method
        : widget.paymentMode;

    final stages = _getStagesForMethod(currentMethod);
    final stage =
        _currentSubStep < stages.length ? stages[_currentSubStep] : stages.last;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: stage.color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: stage.color.withOpacity(0.15),
        ),
      ),
      child: Column(
        children: [
          // Animated icon
          _AnimatedPaymentIcon(
            icon: stage.icon,
            color: stage.color,
          ),
          const SizedBox(height: 16),
          Text(
            stage.label,
            style: tt.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          // Progress dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(stages.length, (i) {
              final isActive = i == _currentSubStep;
              final isDone = i < _currentSubStep;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isActive ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: isDone
                      ? const Color(0xFF10B981)
                      : isActive
                          ? stage.color
                          : scheme.outline.withOpacity(0.15),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _methodLabel(String method) {
    switch (method) {
      case 'CASH':
        return 'Cash';
      case 'CARD':
        return 'Card';
      case 'UPI':
        return 'UPI';
      case 'SPLIT':
        return 'Split payment';
      default:
        return method;
    }
  }
}

// ============================================================================
// Animated payment icon
// ============================================================================

class _AnimatedPaymentIcon extends StatefulWidget {
  final IconData icon;
  final Color color;

  const _AnimatedPaymentIcon({
    required this.icon,
    required this.color,
  });

  @override
  State<_AnimatedPaymentIcon> createState() => _AnimatedPaymentIconState();
}

class _AnimatedPaymentIconState extends State<_AnimatedPaymentIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnim;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _rotationAnim = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _floatAnim = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnim.value),
          child: Transform.rotate(
            angle: _rotationAnim.value,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.color.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Icon(widget.icon, size: 36, color: widget.color),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// Helper model
// ============================================================================

class _SplitPaymentEntry {
  final String method;
  final double amount;

  const _SplitPaymentEntry({required this.method, required this.amount});
}
