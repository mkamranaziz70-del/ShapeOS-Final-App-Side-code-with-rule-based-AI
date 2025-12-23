import 'package:firebase_database/firebase_database.dart';

class BudgetService {
  final DatabaseReference _db =
      FirebaseDatabase.instance.ref().child('userSettings');

  Future<void> saveMonthlyBudget(double budget) async {
    await _db.child('monthlyBudget').set(budget);
  }

  Future<double?> getMonthlyBudget() async {
    final snapshot = await _db.child('monthlyBudget').get();
    if (!snapshot.exists) return null;
    return (snapshot.value as num).toDouble();
  }
}
