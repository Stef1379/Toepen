import 'package:flutter/material.dart';
import 'auth_service.dart';

//TODO: Translate to english (or make some sort of translation functionality)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();

  String error = '';
  bool isRegistering = false;
  bool isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _toggleForm() {
    setState(() {
      isRegistering = !isRegistering;
      error = '';

      _emailController.clear();
      _passwordController.clear();
      _displayNameController.clear();

      _formKey.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Toepen"),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 50.0),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Title(
                      color: Colors.black,
                      child: Text(
                        isRegistering ? "Registreren" : "Inloggen",
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ),
                  if (isRegistering)
                    TextFormField(
                      controller: _displayNameController,
                      decoration: InputDecoration(
                        labelText: 'Naam',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      validator: (val) => val!.isEmpty ? 'Vul je naam in' : null,
                    ),
                  if (isRegistering)
                    const SizedBox(height: 20.0),

                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.email_outlined),
                      errorMaxLines: 2,
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Vul een emailadres in';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                        return 'Vul een geldig emailadres in';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 20.0),

                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Wachtwoord',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.password_outlined),
                      errorMaxLines: 2,
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Vul een wachtwoord in';
                      }
                      if (val.length < 6) {
                        return 'Wachtwoord moet minimaal 6 karakters zijn';
                      }
                      return null;
                    },
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 20.0),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15.0),
                    ),
                    onPressed: isLoading ? null : () async {
                      if (_formKey.currentState!.validate()) {
                        setState(() {
                          isLoading = true;
                          error = '';
                        });

                        try {
                          if (isRegistering) {
                            final userCredential = await _auth.registerWithEmailAndPassword(
                              _emailController.text,
                              _passwordController.text,
                            );
                            if (userCredential != null) {
                              await _auth.updateDisplayName(_displayNameController.text);
                            }
                          } else {
                            error = await _auth.signInWithEmailAndPassword(
                              _emailController.text,
                              _passwordController.text,
                            ) ?? '';
                          }
                        } catch (e) {
                          setState(() {
                            error = e.toString();
                          });
                        } finally {
                          if (mounted) {
                            setState(() {
                              isLoading = false;
                            });
                          }
                        }
                      }
                    },
                    child: isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : Text(
                      isRegistering ? 'Registreren' : 'Inloggen',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 12.0),

                  TextButton(
                    onPressed: _toggleForm,
                    child: Text(
                      isRegistering
                          ? 'Al een account? Log in'
                          : 'Nog geen account? Registreer hier',
                    ),
                  ),

                  if (error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Text(
                        error,
                        style: const TextStyle(color: Colors.red, fontSize: 14.0),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
