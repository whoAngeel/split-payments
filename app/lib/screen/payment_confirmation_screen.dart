import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../service/ws_service.dart';

class PaymentConfirmationScreen extends StatefulWidget {
  final String sessionId;
  final String status;
  const PaymentConfirmationScreen({
    super.key,
    required this.sessionId,
    this.status = 'pending',
  });
  @override
  State<PaymentConfirmationScreen> createState() =>
      _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen> {
  final _ws = WsService();
  late String _status;

  @override
  void initState() {
    super.initState();
    _status = widget.status;

    if (_status == 'pending') {
      _ws.connect(widget.sessionId, (data) {
        if (data['status'] == 'completed') {
          setState(() => _status = 'completed');
          _ws.disconnect();
        }
      });
    }
  }

  @override
  void dispose() {
    _ws.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Center(
        child: _status == 'completed'
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 64, color: Colors.green),
                  const SizedBox(height: 16),
                  const Text('Payment completed!'),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () {
                      context.go('/explorar');
                    },
                    child: Text('Seguir Explorando'),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Waiting for confirmation...'),
                ],
              ),
      ),
    );
  }
}
