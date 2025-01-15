import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth/auth_service.dart';

//TODO: Translate to english (or make some sort of translation functionality)
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _usernameController = TextEditingController(text: user?.displayName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (_usernameController.text != user.displayName) {
          await user.updateDisplayName(_usernameController.text);
        }

        if (_emailController.text != user.email) {
          await user.verifyBeforeUpdateEmail(_emailController.text);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verificatie email verzonden. Check je inbox om de email wijziging te bevestigen.'),
            ),
          );
        }

        setState(() {
          _isEditing = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profiel bijgewerkt!')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Widget _buildProfileForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Gebruikersnaam',
                icon: Icon(Icons.person),
              ),
              enabled: _isEditing,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vul een gebruikersnaam in';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                icon: Icon(Icons.email),
              ),
              enabled: _isEditing,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vul een email adres in';
                }
                if (!value.contains('@')) {
                  return 'Vul een geldig email adres in';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_isEditing) return const SizedBox.shrink();

    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () => _showConfirmationDialog(
            title: 'Wachtwoord wijzigen',
            content: 'Weet je zeker dat je je wachtwoord wilt wijzigen? Er wordt een email verzonden naar ${_emailController.text}',
            onConfirm: () {
              FirebaseAuth.instance.sendPasswordResetEmail(
                email: _emailController.text,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Email verzonden om wachtwoord te wijzigen'),
                ),
              );
              Navigator.of(context).pop(); // Sluit de dialog
            },
          ),
          icon: const Icon(Icons.lock),
          label: const Text('Wachtwoord Wijzigen'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => _showConfirmationDialog(
            title: 'Uitloggen',
            content: 'Weet je zeker dat je wilt uitloggen?',
            onConfirm: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.of(context).pop(); // Sluit de dialog
                Navigator.of(context).pop(); // Ga terug naar vorig scherm
              }
            },
          ),
          icon: const Icon(Icons.logout),
          label: const Text('Uitloggen'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Future<void> _showConfirmationDialog({
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuleren'),
            ),
            TextButton(
              onPressed: onConfirm,
              child: const Text('Bevestigen'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }


  Widget _buildErrorMessage() {
    if (_errorMessage == null) return const SizedBox.shrink();

    return Card(
      color: Colors.red[100],
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Profiel'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _isEditing
            ? () {
          setState(() {
            _isEditing = false;
            final user = FirebaseAuth.instance.currentUser;
            _usernameController.text = user?.displayName ?? '';
            _emailController.text = user?.email ?? '';
          });
        }
            : () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: Icon(_isEditing ? Icons.save : Icons.edit),
          onPressed: _isSaving
              ? null
              : () {
            if (_isEditing) {
              _saveChanges();
            } else {
              setState(() {
                _isEditing = true;
              });
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildErrorMessage(),
              const SizedBox(height: 20),
              _buildProfileForm(),
              const SizedBox(height: 20),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }
}
