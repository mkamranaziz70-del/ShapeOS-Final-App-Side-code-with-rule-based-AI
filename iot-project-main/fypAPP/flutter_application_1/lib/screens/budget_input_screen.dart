import 'package:flutter/material.dart';
import 'budget_analysis_screen.dart';

class BudgetInputScreen extends StatefulWidget {
  const BudgetInputScreen({super.key});

  @override
  State<BudgetInputScreen> createState() => _BudgetInputScreenState();
}

class _BudgetInputScreenState extends State<BudgetInputScreen> {
  final TextEditingController _budgetController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  void _submitBudget() {
    if (!_formKey.currentState!.validate()) return;

    final double monthlyBudget = double.parse(_budgetController.text.trim());

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BudgetAnalysisScreen(monthlyBudget: monthlyBudget),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Monthly Budget'),
        backgroundColor: const Color(0xFF0ABAB5),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monthly Budget',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your monthly budget';
                  }
                  final parsed = double.tryParse(value);
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid positive number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitBudget,
                  child: const Text('Submit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0ABAB5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
