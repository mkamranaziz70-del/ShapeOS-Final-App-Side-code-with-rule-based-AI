import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/device_model.dart';
import '../screens/budget_analysis_screen.dart';

class BudgetCard extends StatefulWidget {
  final List<DeviceModel> appliances;
  const BudgetCard({super.key, required this.appliances});

  @override
  State<BudgetCard> createState() => _BudgetCardState();
}

class _BudgetCardState extends State<BudgetCard> {
  final TextEditingController _budgetController = TextEditingController();
  double? _savedBudget;

  @override
  void initState() {
    super.initState();
    _loadBudget();
  }

  Future<void> _loadBudget() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedBudget = prefs.getDouble('monthly_budget');
    });
  }

  Future<void> _saveBudget(double budget) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('monthly_budget', budget);
    setState(() {
      _savedBudget = budget;
    });
    // Navigate to analysis screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BudgetAnalysisScreen(
          appliances: widget.appliances,
          monthlyBudget: budget,
        ),
      ),
    );
  }

  void _submitBudget() {
    final input = double.tryParse(_budgetController.text);
    if (input == null || input <= 0) return;
    _saveBudget(input);
  }

  @override
  Widget build(BuildContext context) {
    if (_savedBudget != null) {
      return Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BudgetAnalysisScreen(
                  appliances: widget.appliances,
                  monthlyBudget: _savedBudget!,
                ),
              ),
            );
          },
          child: const Text("View Budget Analysis"),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Enter Your Monthly Budget (PKR)",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Monthly Budget",
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _submitBudget,
                child: const Text("Save & Analyze"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
