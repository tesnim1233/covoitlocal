
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const CovoitLocal());
}

const blue = Color(0xFF176B87);
const darkBlue = Color(0xFF123247);
const grey = Color(0xFF718391);
const bg = Color(0xFFF4F7F8);
const green = Color(0xFF36A68A);

class CovoitLocal extends StatelessWidget {
  const CovoitLocal({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CovoitLocal',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        scaffoldBackgroundColor: bg,
      ),
      home: const ConnexionScreen(),
    );
  }
}

// -------------------- GESTION DES COMPTES --------------------

class AccountService {
  static const key = 'covoit_accounts';

  static Future<List<Map<String, dynamic>>> getAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(key);
    if (data == null) return [];

    return List<Map<String, dynamic>>.from(
      (jsonDecode(data) as List).map(
        (e) => Map<String, dynamic>.from(e),
      ),
    );
  }

  static Future<String?> register(
    Map<String, dynamic> account,
  ) async {
    final accounts = await getAccounts();

    final email = account['email'].toString().toLowerCase();
    final phone = account['phone'].toString();

    if (accounts.any(
      (a) => a['email'].toString().toLowerCase() == email,
    )) {
      return 'Cette adresse e-mail existe déjà.';
    }

    if (accounts.any((a) => a['phone'] == phone)) {
      return 'Ce numéro de téléphone existe déjà.';
    }

    accounts.add(account);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(accounts));

    return null;
  }

  static Future<Map<String, dynamic>?> login(
    String identifier,
    String password,
  ) async {
    final accounts = await getAccounts();

    for (final account in accounts) {
      final email = account['email'].toString().toLowerCase();
      final phone = account['phone'].toString();

      if ((identifier.toLowerCase() == email ||
              identifier == phone) &&
          account['password'] == password) {
        return account;
      }
    }

    return null;
  }
}

// -------------------- CHAMP PERSONNALISÉ --------------------

class AppField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType keyboard;
  final VoidCallback? toggle;
  final String? Function(String?)? validator;

  const AppField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.obscure = false,
    this.keyboard = TextInputType.text,
    this.toggle,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E9ED)),
      ),
      child: Row(
        children: [
          Icon(icon, color: blue, size: 17),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: grey,
                    fontSize: 10,
                  ),
                ),
                SizedBox(
                  height: 21,
                  child: TextFormField(
                    controller: controller,
                    obscureText: obscure,
                    keyboardType: keyboard,
                    validator: validator,
                    style: const TextStyle(
                      fontSize: 13,
                      color: darkBlue,
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: darkBlue,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                      errorStyle: const TextStyle(
                        fontSize: 0,
                        height: 0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (toggle != null)
            GestureDetector(
              onTap: toggle,
              child: Icon(
                obscure ? Icons.visibility_off : Icons.visibility,
                size: 17,
                color: grey,
              ),
            ),
        ],
      ),
    );
  }
}

// -------------------- INSCRIPTION --------------------

class InscriptionScreen extends StatefulWidget {
  const InscriptionScreen({super.key});

  @override
  State<InscriptionScreen> createState() =>
      _InscriptionScreenState();
}

class _InscriptionScreenState extends State<InscriptionScreen> {
  final formKey = GlobalKey<FormState>();

  final nom = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();

  String role = 'Passager';
  bool hidePassword = true;
  bool hideConfirm = true;
  bool loading = false;

  @override
  void dispose() {
    nom.dispose();
    email.dispose();
    phone.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  Widget roleCard(String title, IconData icon) {
    final selected = role == title;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => role = title),
        child: Container(
          height: 78,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE5F5F1) : Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected ? green : const Color(0xFFE1E9ED),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? green : blue, size: 22),
              const SizedBox(height: 5),
              Text(
                title,
                style: const TextStyle(
                  color: darkBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? requiredField(String? v) {
    if (v == null || v.trim().isEmpty) return 'Champ obligatoire';
    return null;
  }

  Future<void> createAccount() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final result = await AccountService.register({
      'name': nom.text.trim(),
      'email': email.text.trim().toLowerCase(),
      'phone': phone.text.replaceAll(' ', ''),
      'password': password.text,
      'role': role,
    });

    if (!mounted) return;
    setState(() => loading = false);

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        icon: const Icon(
          Icons.check_circle,
          color: green,
          size: 52,
        ),
        title: const Text('Compte créé !'),
        content: Text(
          'Bienvenue ${nom.text} !\nVotre compte $role a été créé.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => ConnexionScreen(
                    initialIdentifier: email.text.trim(),
                  ),
                ),
              );
            },
            child: const Text(
              'Se connecter',
              style: TextStyle(color: blue),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -24,
              left: 0,
              child: ClipPath(
                clipper: DecorationClipper(),
                child: Container(
                  width: 150,
                  height: 95,
                  color: const Color(0xFFD8F1EB),
                ),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 67),
                    const Text(
                      'CovoitLocal',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: blue,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Créer un compte',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: darkBlue,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Rejoignez notre communauté de covoiturage',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: grey),
                    ),
                    const SizedBox(height: 27),

                    AppField(
                      label: 'Nom et prénom',
                      hint: 'Ex. Tesnim Ouneys',
                      icon: Icons.person,
                      controller: nom,
                      validator: (v) {
                        if (v == null || v.trim().length < 3) {
                          return 'Nom invalide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    AppField(
                      label: 'Adresse e-mail',
                      hint: 'exemple@email.com',
                      icon: Icons.email_outlined,
                      controller: email,
                      keyboard: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null ||
                            !RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                                .hasMatch(v.trim())) {
                          return 'E-mail invalide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    AppField(
                      label: 'Téléphone',
                      hint: '+216 XX XXX XXX',
                      icon: Icons.phone,
                      controller: phone,
                      keyboard: TextInputType.phone,
                      validator: (v) {
                        final p = (v ?? '').replaceAll(
                          RegExp(r'[\s-]'),
                          '',
                        );
                        if (!RegExp(r'^(\+216)?[0-9]{8}$').hasMatch(p)) {
                          return 'Téléphone invalide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    AppField(
                      label: 'Mot de passe',
                      hint: '••••••••',
                      icon: Icons.lock_outline,
                      controller: password,
                      obscure: hidePassword,
                      toggle: () => setState(
                        () => hidePassword = !hidePassword,
                      ),
                      validator: (v) {
                        if (v == null || v.length < 8) {
                          return 'Minimum 8 caractères';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    AppField(
                      label: 'Confirmer le mot de passe',
                      hint: '••••••••',
                      icon: Icons.lock_outline,
                      controller: confirm,
                      obscure: hideConfirm,
                      toggle: () => setState(
                        () => hideConfirm = !hideConfirm,
                      ),
                      validator: (v) {
                        if (v != password.text) {
                          return 'Mots de passe différents';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 22),
                    const Text(
                      'Je souhaite m’inscrire comme :',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: darkBlue,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        roleCard('Passager', Icons.person_outline),
                        const SizedBox(width: 14),
                        roleCard('Conducteur', Icons.directions_car),
                      ],
                    ),
                    const SizedBox(height: 22),

                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: loading ? null : createAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: blue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: loading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Créer mon compte',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ConnexionScreen(),
                          ),
                        );
                      },
                      child: const Text.rich(
                        TextSpan(
                          text: 'Vous avez déjà un compte ? ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: blue,
                          ),
                          children: [
                            TextSpan(
                              text: 'Se connecter',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------- CONNEXION --------------------

class ConnexionScreen extends StatefulWidget {
  final String? initialIdentifier;

  const ConnexionScreen({
    super.key,
    this.initialIdentifier,
  });

  @override
  State<ConnexionScreen> createState() => _ConnexionScreenState();
}

class _ConnexionScreenState extends State<ConnexionScreen> {
  final formKey = GlobalKey<FormState>();
  final identifier = TextEditingController();
  final password = TextEditingController();

  bool hidePassword = true;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    identifier.text = widget.initialIdentifier ?? '';
  }

  @override
  void dispose() {
    identifier.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> connect() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final account = await AccountService.login(
      identifier.text.trim(),
      password.text,
    );

    if (!mounted) return;
    setState(() => loading = false);

    if (account == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Identifiant ou mot de passe incorrect.'),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(account: account),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -24,
              left: 0,
              child: ClipPath(
                clipper: DecorationClipper(),
                child: Container(
                  width: 150,
                  height: 95,
                  color: const Color(0xFFD8F1EB),
                ),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 112),
                    const Text(
                      'CovoitLocal',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        color: blue,
                      ),
                    ),
                    const SizedBox(height: 48),
                    const Text(
                      'Bienvenue !',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: darkBlue,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Connectez-vous pour continuer',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: grey),
                    ),
                    const SizedBox(height: 49),

                    AppField(
                      label: 'E-mail ou téléphone',
                      hint: 'Votre identifiant',
                      icon: Icons.email_outlined,
                      controller: identifier,
                      keyboard: TextInputType.emailAddress,
                      validator: (v) =>
                          v == null || v.trim().isEmpty
                              ? 'Identifiant obligatoire'
                              : null,
                    ),
                    const SizedBox(height: 14),

                    AppField(
                      label: 'Mot de passe',
                      hint: '••••••••',
                      icon: Icons.lock_outline,
                      controller: password,
                      obscure: hidePassword,
                      toggle: () => setState(
                        () => hidePassword = !hidePassword,
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty
                              ? 'Mot de passe obligatoire'
                              : null,
                    ),

                    const SizedBox(height: 24),

                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'La récupération du mot de passe nécessite un service backend.',
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'Mot de passe oublié ?',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: blue,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: loading ? null : connect,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: blue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: loading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Se connecter',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 27),
                    const Text(
                      'ou',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: grey),
                    ),
                    const SizedBox(height: 27),

                    Container(
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFFE1E9ED),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Continuer avec Google',
                        style: TextStyle(
                          color: darkBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 58),

                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const InscriptionScreen(),
                          ),
                        );
                      },
                      child: const Text.rich(
                        TextSpan(
                          text: "Pas encore de compte ? ",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: blue,
                          ),
                          children: [
                            TextSpan(
                              text: "S'inscrire",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------- ACCUEIL APRÈS CONNEXION --------------------

class HomeScreen extends StatelessWidget {
  final Map<String, dynamic> account;

  const HomeScreen({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    final role = account['role'];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        title: const Text('CovoitLocal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const ConnexionScreen(),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                role == 'Passager'
                    ? Icons.person
                    : Icons.directions_car,
                size: 75,
                color: blue,
              ),
              const SizedBox(height: 20),
              Text(
                'Bienvenue ${account['name']} !',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: darkBlue,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Espace $role',
                style: const TextStyle(
                  fontSize: 17,
                  color: blue,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                account['email'],
                style: const TextStyle(color: grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------- DÉCORATION --------------------

class DecorationClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..quadraticBezierTo(
        size.width - 20,
        size.height * 0.65,
        0,
        size.height,
      )
      ..close();
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
