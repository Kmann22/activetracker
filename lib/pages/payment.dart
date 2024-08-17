import 'package:activetracker/services/stripe_service.dart';
import 'package:flutter/material.dart';

class PaymentScreen extends StatefulWidget {
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Stripe Payment'),
      ),
      body: SizedBox.expand(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center, // Corrected alignment spelling
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            MaterialButton(
              onPressed: () {
                // Handle payment logic here
                StripeService.instance.makePayment();
              },
              color: Colors.green,
              child: const Text(
                "Make Payment",
                style: TextStyle(
                    color:
                        Colors.white), // Added text color for better visibility
              ),
            ),
          ],
        ),
      ),
    );
  }
}
