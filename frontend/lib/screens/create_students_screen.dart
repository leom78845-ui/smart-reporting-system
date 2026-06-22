// lib/screens/create_students_screen.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CreateStudentsScreen extends StatefulWidget {
  const CreateStudentsScreen({super.key});

  @override
  State<CreateStudentsScreen> createState() => _CreateStudentsScreenState();
}

class _CreateStudentsScreenState extends State<CreateStudentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Single Student fields
  final _singleRollController = TextEditingController();
  final _singleNameController = TextEditingController();
  final _singlePasswordController = TextEditingController(text: "HU-Student123");
  String _singleProgram = "bs";
  bool _isSingleLoading = false;

  // Bulk Student fields
  final _bulkPrefixController = TextEditingController();
  final _bulkStartController = TextEditingController();
  final _bulkEndController = TextEditingController();
  final _bulkPasswordController = TextEditingController(text: "HU-Student123");
  String _bulkProgram = "bs";
  bool _isBulkLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _singleRollController.dispose();
    _singleNameController.dispose();
    _singlePasswordController.dispose();
    _bulkPrefixController.dispose();
    _bulkStartController.dispose();
    _bulkEndController.dispose();
    _bulkPasswordController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // CREATE SINGLE STUDENT
  // ---------------------------------------------------------------------------
  Future<void> _createSingleStudent() async {
    final roll = _singleRollController.text.trim();
    final name = _singleNameController.text.trim();
    final password = _singlePasswordController.text.trim();

    if (roll.isEmpty || name.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill roll number, name, and default password")),
      );
      return;
    }

    setState(() => _isSingleLoading = true);

    final success = await ApiService.createStudent(
      rollNumber: roll,
      name: name,
      program: _singleProgram,
      password: password,
    );

    setState(() => _isSingleLoading = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Student created successfully! Password: $password")),
      );
      _singleRollController.clear();
      _singleNameController.clear();
      // Keep password set to HU-Student123 as default helper
      _singlePasswordController.text = "HU-Student123";
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to create student. User may already exist.")),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // BULK CREATE STUDENTS
  // ---------------------------------------------------------------------------
  Future<void> _createBulkStudents() async {
    final prefix = _bulkPrefixController.text.trim();
    final start = _bulkStartController.text.trim();
    final end = _bulkEndController.text.trim();
    final password = _bulkPasswordController.text.trim();

    if (prefix.isEmpty || start.isEmpty || end.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields for range creation")),
      );
      return;
    }

    if (int.tryParse(start) == null || int.tryParse(end) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Start and End bounds must be valid numbers")),
      );
      return;
    }

    setState(() => _isBulkLoading = true);

    final success = await ApiService.bulkCreateStudents(
      prefix: prefix,
      start: start,
      end: end,
      program: _bulkProgram,
      password: password,
    );

    setState(() => _isBulkLoading = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Batch of student accounts created successfully with password: $password")),
      );
      _bulkPrefixController.clear();
      _bulkStartController.clear();
      _bulkEndController.clear();
      _bulkPasswordController.text = "HU-Student123";
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to perform bulk creation. Check fields.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Management"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person_add), text: "Single Student"),
            Tab(icon: Icon(Icons.group_add), text: "Bulk Generation"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSingleStudentForm(),
          _buildBulkStudentsForm(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SINGLE STUDENT FORM UI
  // ---------------------------------------------------------------------------
  Widget _buildSingleStudentForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Create a single student account. Set a default password that they will use to login initially.",
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _singleRollController,
            decoration: const InputDecoration(
              labelText: "Roll Number",
              hintText: "e.g. 301-221016",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _singleNameController,
            decoration: const InputDecoration(
              labelText: "Full Name",
              hintText: "e.g. John Doe",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _singlePasswordController,
            decoration: const InputDecoration(
              labelText: "Default Password",
              hintText: "e.g. HU-Student123",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _singleProgram,
            decoration: const InputDecoration(
              labelText: "Program (BS sets 4 years, MS sets 2 years)",
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: "bs", child: Text("BS (4 Years Expiration)")),
              DropdownMenuItem(value: "ms", child: Text("MS (2 Years Expiration)")),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _singleProgram = val);
            },
          ),
          const SizedBox(height: 32),
          _isSingleLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton.icon(
                  onPressed: _createSingleStudent,
                  icon: const Icon(Icons.check),
                  label: const Text("Create Student Account"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BULK STUDENTS FORM UI
  // ---------------------------------------------------------------------------
  Widget _buildBulkStudentsForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Generate a batch of student accounts. Enter prefix and range bounds, and define the shared default password.",
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _bulkPrefixController,
            decoration: const InputDecoration(
              labelText: "Roll Number Prefix",
              hintText: "e.g. 301-2210",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _bulkStartController,
                  decoration: const InputDecoration(
                    labelText: "Start Range",
                    hintText: "e.g. 001",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _bulkEndController,
                  decoration: const InputDecoration(
                    labelText: "End Range",
                    hintText: "e.g. 016",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _bulkPasswordController,
            decoration: const InputDecoration(
              labelText: "Shared Default Password",
              hintText: "e.g. HU-Student123",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _bulkProgram,
            decoration: const InputDecoration(
              labelText: "Program (BS sets 4 years, MS sets 2 years)",
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: "bs", child: Text("BS (4 Years Expiration)")),
              DropdownMenuItem(value: "ms", child: Text("MS (2 Years Expiration)")),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _bulkProgram = val);
            },
          ),
          const SizedBox(height: 32),
          _isBulkLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton.icon(
                  onPressed: _createBulkStudents,
                  icon: const Icon(Icons.bolt),
                  label: const Text("Generate Batch of Accounts"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
        ],
      ),
    );
  }
}
