import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

// -------------------------------------------------------------
// Root Widget of the app
// -------------------------------------------------------------
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,

      // 🌐 Theme Configuration
      theme: ThemeData(
        // 💎 Modern & Professional Blue Theme
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          primary: Colors.indigo,
          secondary: Colors.lightBlueAccent,
        ),

        scaffoldBackgroundColor: Colors.grey[50],
        useMaterial3: true,

        // 🟦 AppBar styling
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          elevation: 4,
        ),

        // 🟦 Elevated Button styling
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // 🟦 TextField styling
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.indigo, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // 🏠 Starting screen
      home: const HomeScreen(),
    );
  }
}

// -------------------------------------------------------------
// Screen 1: Home Screen — collects name and income
// -------------------------------------------------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 🧾 Text controllers for input fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _incomeController = TextEditingController();

  // 👤 Stores the entered name (for welcome message)
  String _enteredName = "";

  // ➡️ Navigate to AddExpenseScreen (next screen)
  void _navigateToAddExpense() {
    final String userName = _nameController.text.trim();
    final double totalIncome = double.tryParse(_incomeController.text) ?? 0.0;

    // 🧠 Validation: Check for missing name or invalid income
    if (userName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (totalIncome <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid monthly income.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 🧭 Move to AddExpenseScreen with entered data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(
          userName: userName,
          totalIncome: totalIncome,
        ),
      ),
    );
  }

  @override
  void dispose() {
    // 🧹 Clean up controllers to avoid memory leaks
    _nameController.dispose();
    _incomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Expense Tracker'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 💳 Input container (Name + Income)
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🧍 Name input field
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Enter Your Name',
                      prefixIcon: Icon(Icons.person),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _enteredName = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // 💰 Income input field
                  TextField(
                    controller: _incomeController,
                    decoration: const InputDecoration(
                      labelText: 'Enter Your Total Monthly Income (PKR)',
                      prefixIcon: Icon(Icons.account_balance_wallet),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 👋 Dynamic welcome message
            Text(
              'Welcome, ${_enteredName.isEmpty ? '...' : _enteredName}!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 30),

            // 🚀 Button to navigate to Add Expenses screen
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _navigateToAddExpense,
                  child: const Text('Add Expenses'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// Screen 2: Add Expense Screen — records expenses & calculates result
// -------------------------------------------------------------
class AddExpenseScreen extends StatefulWidget {
  final String userName;
  final double totalIncome;

  const AddExpenseScreen({
    super.key,
    required this.userName,
    required this.totalIncome,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  // 💵 Controllers for each expense category
  final _groceryController = TextEditingController();
  final _billController = TextEditingController();
  final _educationController = TextEditingController();
  final _entertainmentController = TextEditingController();
  final _savingsController = TextEditingController();
  final _travelController = TextEditingController();

  // 🧮 Holds all controllers for iteration
  late List<TextEditingController> _controllers;

  // 📊 Output message and color state
  String _resultMessage = '';
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _controllers = [
      _groceryController,
      _billController,
      _educationController,
      _entertainmentController,
      _savingsController,
      _travelController,
    ];
  }

  @override
  void dispose() {
    // 🧹 Dispose all controllers to free memory
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // 🧾 Builds a single expense input row
  Widget _buildExpenseRow(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // Label text (e.g., Grocery)
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(width: 10),

          // Input box
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 45, // Consistent height for all text boxes
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  hintText: '0.00',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🧮 Calculate total expenses and remaining/saved income
  void _calculateExpenses() {
    double totalExpenses = 0.0;

    // Sum up all entered expenses
    for (var controller in _controllers) {
      totalExpenses += double.tryParse(controller.text) ?? 0.0;
    }

    // Calculate remaining balance
    double remainingAmount = widget.totalIncome - totalExpenses;

    // 💬 Display result
    setState(() {
      if (remainingAmount >= 0) {
        _resultMessage =
        "You saved PKR ${remainingAmount.toStringAsFixed(2)} this month!";
        _isSaved = true;
      } else {
        _resultMessage =
        "You overspent by PKR ${remainingAmount.abs().toStringAsFixed(2)} this month.";
        _isSaved = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Expenses for ${widget.userName}'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 💰 Income display card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.primary),
                ),
                child: Text(
                  'Your Income: PKR ${widget.totalIncome.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),

              // 🧾 Expense input rows
              _buildExpenseRow('Grocery', _groceryController),
              _buildExpenseRow('Electricity & Gas Bill', _billController),
              _buildExpenseRow('Education', _educationController),
              _buildExpenseRow('Entertainment', _entertainmentController),
              _buildExpenseRow('Savings', _savingsController),
              _buildExpenseRow('Travel', _travelController),

              const SizedBox(height: 20),

              // 🧮 Submit and calculate button
              ElevatedButton(
                onPressed: _calculateExpenses,
                child: const Text('Submit & Calculate'),
              ),
              const SizedBox(height: 20),

              // 📊 Result message (Saved or Overspent)
              if (_resultMessage.isNotEmpty)
                Text(
                  _resultMessage,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _isSaved
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}