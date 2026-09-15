import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/services/emergency_contact_store.dart';
import '../../shared/widgets/big_button.dart';

class EmergencyContactScreen extends StatefulWidget {
  const EmergencyContactScreen({super.key});

  @override
  State<EmergencyContactScreen> createState() => _EmergencyContactScreenState();
}

class _EmergencyContactScreenState extends State<EmergencyContactScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final store = Provider.of<EmergencyContactStore>(context, listen: false);
    _nameController = TextEditingController(text: store.contact?.name ?? '');
    _phoneController = TextEditingController(text: store.contact?.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final store = Provider.of<EmergencyContactStore>(context, listen: false);
      final success = await store.saveContact(
        name: _nameController.text,
        phoneNumber: _phoneController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Emergency contact saved!' : 'Invalid phone number.'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contact'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const Icon(Icons.contact_phone_outlined, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Set Emergency Contact',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This contact will receive your SOS alert and location if battery falls critically low or you trigger emergency SOS.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number (e.g. +91 9876543210)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a phone number';
                    }
                    if (!EmergencyContactStore.validatePhone(val)) {
                      return 'Enter a valid phone number (3-15 digits)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                BigButton(
                  label: 'Save Contact',
                  icon: Icons.save,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
