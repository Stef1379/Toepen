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

  String email = '';
  String password = '';
  String displayName = '';
  String error = '';
  bool isRegistering = false;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Toepen"),
      ),
      body: Center( // Wrap with Center
        child: SingleChildScrollView( // Add ScrollView for smaller screens
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 50.0),
            constraints: const BoxConstraints(maxWidth: 400), // Add max width
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // Center column content
                crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch widgets horizontally
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
                      decoration: const InputDecoration(
                        labelText: 'Naam',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val!.isEmpty ? 'Vul je naam in' : null,
                      onChanged: (val) {
                        setState(() => displayName = val);
                      },
                    ),
                  if (isRegistering)
                    const SizedBox(height: 20.0),

                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val!.isEmpty ? 'Vul een email in' : null,
                    onChanged: (val) {
                      setState(() => email = val);
                    },
                  ),
                  const SizedBox(height: 20.0),

                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Wachtwoord',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (val) => val!.length < 6
                        ? 'Wachtwoord moet minimaal 6 karakters zijn'
                        : null,
                    onChanged: (val) {
                      setState(() => password = val);
                    },
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
                              email,
                              password,
                            );
                            if (userCredential != null) {
                              await _auth.updateDisplayName(displayName);
                            }
                          } else {
                            await _auth.signInWithEmailAndPassword(
                              email,
                              password,
                            );
                          }
                        } catch (e) {
                          setState(() {
                            error = e.toString();
                            isLoading = false;
                          });
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
                    onPressed: () {
                      setState(() {
                        isRegistering = !isRegistering;
                        error = '';
                      });
                    },
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


