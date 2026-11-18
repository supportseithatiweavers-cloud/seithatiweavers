import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

const mediaApiUrl = String.fromEnvironment(
  'MEDIA_API_URL',
  defaultValue:
      'https://seithati-weavers-media.support-seithatiweavers.workers.dev',
);
const contentDocument = 'site/content';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: kIsWeb
        ? const FirebaseOptions(
            apiKey: String.fromEnvironment(
              'FIREBASE_API_KEY',
              defaultValue: 'AIzaSyB8_JUcPXWh38XSuEPHUv-u9YgDZZFozIk',
            ),
            authDomain: String.fromEnvironment(
              'FIREBASE_AUTH_DOMAIN',
              defaultValue: 'seithati-weavers.firebaseapp.com',
            ),
            projectId: String.fromEnvironment(
              'FIREBASE_PROJECT_ID',
              defaultValue: 'seithati-weavers',
            ),
            storageBucket: String.fromEnvironment(
              'FIREBASE_STORAGE_BUCKET',
              defaultValue: 'seithati-weavers.firebasestorage.app',
            ),
            messagingSenderId: String.fromEnvironment(
              'FIREBASE_MESSAGING_SENDER_ID',
              defaultValue: '881602360348',
            ),
            appId: String.fromEnvironment(
              'FIREBASE_APP_ID',
              defaultValue: '1:881602360348:web:97a6b2a8461223ad05dbd9',
            ),
            measurementId: String.fromEnvironment(
              'FIREBASE_MEASUREMENT_ID',
              defaultValue: 'G-B5GV0S496T',
            ),
          )
        : null,
  );
  runApp(const SeithatiAdminApp());
}

Future<void> _signOut() async {
  await FirebaseAuth.instance.signOut();
  if (!kIsWeb) await GoogleSignIn().signOut();
}

class SeithatiAdminApp extends StatelessWidget {
  const SeithatiAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seithati Weavers Admin',
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Color(0xff2563eb),
          onPrimary: Colors.white,
          primaryContainer: Color(0xffdbeafe),
          onPrimaryContainer: Color(0xff1e40af),
          secondary: Color(0xff3b82f6),
          onSecondary: Colors.white,
          secondaryContainer: Color(0xffeff6ff),
          onSecondaryContainer: Color(0xff1e3a8a),
          tertiary: Color(0xffbd1735),
          onTertiary: Colors.white,
          surface: Colors.white,
          onSurface: Color(0xff0f172a),
          onSurfaceVariant: Color(0xff64748b),
          outline: Color(0xffe2e8f0),
        ),
        scaffoldBackgroundColor: const Color(0xfff8fafc),
        fontFamily: 'DM Sans',
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xffe2e8f0)),
          ),
        ),
        inputDecorationTheme: InputDecorationThemeData(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xffcbd5e1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xffcbd5e1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xff2563eb), width: 1.5),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xff2563eb),
            foregroundColor: Colors.white,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xff2563eb),
            side: const BorderSide(color: Color(0xffbfdbfe)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xff2563eb),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xfff1f5f9),
          selectedColor: const Color(0xffdbeafe),
          side: const BorderSide(color: Color(0xffe2e8f0)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          labelStyle: const TextStyle(
            color: Color(0xff334155),
            fontWeight: FontWeight.w500,
          ),
          secondaryLabelStyle: const TextStyle(
            color: Color(0xff1d4ed8),
            fontWeight: FontWeight.w600,
          ),
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            fontFamily: 'Playfair Display',
            fontWeight: FontWeight.w700,
          ),
          titleLarge: TextStyle(
            fontFamily: 'Playfair Display',
            fontWeight: FontWeight.w600,
          ),
        ),
        useMaterial3: true,
      ),
      home: const AdminAuthGate(),
    );
  }
}

class AdminAuthGate extends StatelessWidget {
  const AdminAuthGate({super.key});

  Future<bool> _isAllowlisted(User user) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('admins')
        .doc(user.uid)
        .get();
    return snapshot.exists && snapshot.data()?['email'] == user.email;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingPage();
        }
        final user = authSnapshot.data;
        if (user == null) return const GoogleSignInPage();

        return FutureBuilder<bool>(
          key: ValueKey(user.uid),
          future: _isAllowlisted(user),
          builder: (context, accessSnapshot) {
            if (accessSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingPage();
            }
            if (accessSnapshot.data == true) return const AdminDashboard();
            return AccessDeniedPage(
              onSignOut: _signOut,
            );
          },
        );
      },
    );
  }
}

class _LoadingPage extends StatelessWidget {
  const _LoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class GoogleSignInPage extends StatefulWidget {
  const GoogleSignInPage({super.key});

  @override
  State<GoogleSignInPage> createState() => _GoogleSignInPageState();
}

class _GoogleSignInPageState extends State<GoogleSignInPage> {
  bool _busy = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      UserCredential result;
      if (kIsWeb) {
        result = await FirebaseAuth.instance.signInWithPopup(
          GoogleAuthProvider(),
        );
      } else {
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return;
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        result = await FirebaseAuth.instance.signInWithCredential(credential);
      }
      final user = result.user;
      if (user == null) throw StateError('Google sign-in returned no user.');

      final admin = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();
      if (!admin.exists || admin.data()?['email'] != user.email) {
        await _signOut();
        throw StateError(
          'This Google account is not on the Seithati Weavers admin list.',
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/seithati-weavers-logo.png',
                  width: 180,
                  height: 128,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 12),
                Text(
                  'Seithati Weavers',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(_ui(context, 'Sign in with an approved Google account.')),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _busy ? null : _signIn,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login),
                  label: const Text('Continue with Google'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AccessDeniedPage extends StatelessWidget {
  const AccessDeniedPage({required this.onSignOut, super.key});

  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48),
              const SizedBox(height: 12),
              Text(
                  _ui(context, 'This Google account is not an administrator.')),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onSignOut,
                child: Text(_ui(context, 'Sign out')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _sesothoUiText = <String, String>{
  'Home': 'Lehae',
  'Crafts': 'Mesebetsi ea matsoho',
  'Website text': 'Mongolo oa webosaete',
  'Images & contact': 'Lifoto le lintlha tsa puisano',
  'Content': 'Mongolo',
  'Media': 'Lifoto',
  'Seithati Weavers · Content studio': 'Seithati Weavers · Setsi sa taolo',
  'Sign out': 'Tsoa',
  'Welcome to your content studio': 'Rea u amohela setsing sa taolo',
  'Keep your stories, handmade collection and website details up to date.':
      'Laola lipale, pokello ea mesebetsi ea matsoho le lintlha tsa webosaete.',
  'Add a craft': 'Kenya mosebetsi',
  'Add new craft': 'Kenya mosebetsi o mocha',
  'Add a new craft': 'Kenya mosebetsi o mocha',
  'Crafts in catalog': 'Mesebetsi e lethathamong',
  'Languages': 'Lipuo',
  'English and Sesotho': 'Senyesemane le Sesotho',
  'Image storage': 'Polokelo ea litšoantšo',
  'Connected': 'E hokahane',
  'Manage your website': 'Laola webosaete ea hau',
  'Craft collection': 'Pokello ea mesebetsi',
  'Add products, upload photos and update details.':
      'Kenya lihlahisoa, linepe le lintlha.',
  'Edit the English and Sesotho website copy.':
      'Fetola mongolo oa webosaete ka Senyesemane le Sesotho.',
  'Update section imagery and contact details.':
      'Fetola linepe tsa likarolo le lintlha tsa puisano.',
  'crafts': 'mesebetsi',
  'craft': 'mosebetsi',
  'Manage products, descriptions and gallery photos.':
      'Laola lihlahisoa, litlhaloso le linepe.',
  'Clear search': 'Hlakola patlo',
  'Added · ': 'E kentsoe · ',
  'On website': 'E webosaeteng',
  'Bags & accessories': 'Mekotla le lisebelisoa',
  'New craft — add details': 'Mosebetsi o mocha — kenya lintlha',
  'Product details and image': 'Lintlha tsa sehlahisoa le setšoantšo',
  'Image preview unavailable': 'Setšoantšo ha se bonahale',
  'Add a product photo': 'Kenya setšoantšo sa sehlahisoa',
  'Image uploaded and published.': 'Setšoantšo se kentsoe webosaeteng.',
  'Contact details saved.': 'Lintlha tsa puisano li bolokiloe.',
  'Add or edit a text field': 'Kenya kapa fetola lebokose la mongolo',
  'Text key (for example storyTitle)':
      'Senotlolo sa mongolo (mohlala storyTitle)',
  'Add': 'Kenya',
  'Use a translation key, optionally with dots.':
      'Sebelisa senotlolo sa phetolelo; u ka sebelisa matheba.',
  'Language': 'Puo',
  'Change language': 'Fetola puo',
  'Upload image': 'Kenya setšoantšo',
  'image': 'setšoantšo',
  'Hero': 'Karolo ea pele',
  'Story': 'Pale',
  'Cta': 'Memo',
  'Showcase Bags': 'Pokello ea mekotla',
  'Showcase Home': 'Pokello ea lapeng',
  'Showcase Accessories': 'Pokello ea lisebelisoa',
  'Process 01': 'Mohato oa 1',
  'Process 02': 'Mohato oa 2',
  'Process 03': 'Mohato oa 3',
  'Search crafts': 'Batla mesebetsi',
  'All crafts': 'Mesebetsi eohle',
  'Bags': 'Mekotla',
  'Home decor': 'Mekhabiso ea lapeng',
  'Accessories': 'Lisebelisoa',
  'Wearables': 'Liaparo',
  'Your collection is ready to grow': 'Pokello ea hau e se e loketse ho hola',
  'No crafts found': 'Ha ho mesebetsi e fumanoeng',
  'Add your first product and its photo to get started.':
      'Kenya sehlahisoa sa pele le setšoantšo sa sona.',
  'Try another search or category.':
      'Leka ho batla kapa khetha sehlopha se seng.',
  'Choose a product category': 'Khetha sehlopha sa sehlahisoa',
  'Edit craft': 'Fetola mosebetsi',
  'Close': 'Koala',
  'Delete this craft?': 'Hlakola mosebetsi ona?',
  'Untitled craft': 'Mosebetsi o se nang lebitso',
  'will be removed from the website catalog.':
      'o tla tlosoa lethathamong la webosaete.',
  'Cancel': 'Hana',
  'Delete craft': 'Hlakola mosebetsi',
  'Craft deleted from the catalog.': 'Mosebetsi o hlakotsoe lethathamong.',
  'Could not delete craft:': 'Ha hoa khoneha ho hlakola mosebetsi:',
  'Enter a name and description before saving.':
      'Kenya lebitso le tlhaloso pele u boloka.',
  'Use one of these categories: bags, home, accessories, wearables.':
      'Khetha se seng sa lihlopha tsena: mekotla, lapeng, lisebelisoa kapa liaparo.',
  'The built-in crafts cannot be edited here.':
      'Mesebetsi e seng e le teng e ke ke ea fetoloa mona.',
  'Upload a product photo before saving this craft.':
      'Kenya setšoantšo sa sehlahisoa pele u boloka mosebetsi ona.',
  'Product name': 'Lebitso la sehlahisoa',
  'Category': 'Sehlopha',
  'Category label on website': 'Lebitso la sehlopha webosaeteng',
  'Badge (optional)': 'Letšoao (ha ho hlokahale)',
  'Product description': 'Tlhaloso ea sehlahisoa',
  'Image description for accessibility': 'Tlhaloso ea setšoantšo',
  'Photo required. If no file dialog opens, launch this page directly in Chrome or Edge.':
      'Setšoantšo sea hlokahala. Ha fensetere ea lifaele e sa bulehe, bula leqephe lena ka Chrome kapa Edge.',
  'Product photo ready': 'Setšoantšo sa sehlahisoa se lokile',
  'Uploading…': 'E kenya…',
  'Upload photo': 'Kenya setšoantšo',
  'Save craft': 'Boloka mosebetsi',
  'Saving…': 'E boloka…',
  'Craft saved.': 'Mosebetsi o bolokiloe.',
  'Craft actions': 'Liketso tsa mosebetsi',
  'English': 'Senyesemane',
  'Sesotho': 'Sesotho',
  'Section images': 'Litšoantšo tsa likarolo',
  'Upload a JPEG, PNG, or WebP image up to 10 MB.':
      'Kenya setšoantšo sa JPEG, PNG kapa WebP se sa feteng 10 MB.',
  'Using the current website image': 'Ho sebelisoa setšoantšo sa webosaete',
  'Contact information': 'Lintlha tsa puisano',
  'Phone': 'Mohala',
  'Whatsapp': 'WhatsApp',
  'Email': 'Imeile',
  'Full Address': 'Aterese e feletseng',
  'Save contact information': 'Boloka lintlha tsa puisano',
  'Add a photo': 'Kenya setšoantšo',
  'Website text saved.': 'Mongolo oa webosaete o bolokiloe.',
  'Additional text fields': 'Mabokose a mang a mongolo',
  'Add another text field': 'Kenya lebokose le leng la mongolo',
  'Save website text': 'Boloka mongolo oa webosaete',
  'This Google account is not an administrator.':
      'Akhaonto ena ea Google ha se ea motsamaisi.',
  'Sign in with an approved Google account.':
      'Kena ka akhaonto ea Google e lumelletsoeng.',
  'Continue with Google': 'Tsoela pele ka Google',
};

class _AdminLanguageScope extends InheritedWidget {
  const _AdminLanguageScope({
    required this.sesotho,
    required super.child,
  });

  final bool sesotho;

  static bool isSesotho(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<_AdminLanguageScope>()
            ?.sesotho ??
        false;
  }

  @override
  bool updateShouldNotify(_AdminLanguageScope oldWidget) {
    return sesotho != oldWidget.sesotho;
  }
}

String _ui(BuildContext context, String english) {
  return _AdminLanguageScope.isSesotho(context)
      ? _sesothoUiText[english] ?? english
      : english;
}

String _uiFor(bool sesotho, String english) {
  return sesotho ? _sesothoUiText[english] ?? english : english;
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background =
        isError ? colors.errorContainer : const Color(0xffe6f4ea);
    final foreground =
        isError ? colors.onErrorContainer : const Color(0xff216e39);

    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: foreground,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _sesotho = false;
  Timer? _presenceTimer;
  final _presenceRef =
      FirebaseFirestore.instance.collection('site').doc('adminPresence');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startPresenceHeartbeat();
  }

  void _startPresenceHeartbeat() {
    _presenceTimer?.cancel();
    unawaited(_updatePresence(true));
    _presenceTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(_updatePresence(true)),
    );
  }

  Future<void> _updatePresence(bool online) async {
    try {
      await _presenceRef.set({
        'online': online,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (error) {
      debugPrint('Could not update admin availability: $error');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startPresenceHeartbeat();
      return;
    }
    _presenceTimer?.cancel();
    _presenceTimer = null;
    unawaited(_updatePresence(false));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _presenceTimer?.cancel();
    unawaited(_updatePresence(false));
    super.dispose();
  }

  static const _sections = [
    (
      label: 'Home',
      mobileLabel: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    (
      label: 'Crafts',
      mobileLabel: 'Crafts',
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
    ),
    (
      label: 'Website text',
      mobileLabel: 'Content',
      icon: Icons.article_outlined,
      selectedIcon: Icons.article,
    ),
    (
      label: 'Images & contact',
      mobileLabel: 'Media',
      icon: Icons.photo_library_outlined,
      selectedIcon: Icons.photo_library,
    ),
    (
      label: 'Chats',
      mobileLabel: 'Chats',
      icon: Icons.chat_bubble_outline,
      selectedIcon: Icons.chat_bubble,
    ),
  ];

  void _selectSection(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _openProfileEditor() async {
    await showDialog<void>(
      context: context,
      builder: (context) => const _AdminProfileEditor(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final wide = screenWidth >= 900;
    final compact = screenWidth < 560;
    final user = FirebaseAuth.instance.currentUser;
    final pages = [
      _AdminOverview(onSelectSection: _selectSection),
      const CraftsEditor(),
      const WebsiteTextEditor(),
      const ImagesAndContactEditor(),
      const CustomerMessagesViewer(),
    ];

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      bottomNavigationBar: compact
          ? NavigationBar(
              height: 68,
              selectedIndex: _selectedIndex,
              onDestinationSelected: _selectSection,
              destinations: [
                for (final section in _sections)
                  NavigationDestination(
                    icon: Icon(section.icon),
                    selectedIcon: Icon(section.selectedIcon),
                    label: _uiFor(_sesotho, section.mobileLabel),
                  ),
              ],
            )
          : null,
      drawer: wide
          ? null
          : Drawer(
              width: 280,
              child: _AdminSidebar(
                width: 280,
                sections: _sections,
                selectedIndex: _selectedIndex,
                sesotho: _sesotho,
                onSelected: (index) {
                  Navigator.of(context).pop();
                  _selectSection(index);
                },
                onSignOut: _signOut,
              ),
            ),
      body: SafeArea(
        child: _AdminLanguageScope(
          sesotho: _sesotho,
          child: Row(
            children: [
              if (wide)
                _AdminSidebar(
                  width: 184,
                  sections: _sections,
                  selectedIndex: _selectedIndex,
                  sesotho: _sesotho,
                  onSelected: _selectSection,
                  onSignOut: _signOut,
                ),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 84,
                      padding: EdgeInsets.symmetric(
                        horizontal: wide ? 24 : 20,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xffe4dfd9)),
                        ),
                      ),
                      child: Row(
                        children: [
                          if (!wide) ...[
                            Builder(
                              builder: (context) => IconButton(
                                tooltip: 'Open navigation menu',
                                onPressed: () =>
                                    Scaffold.of(context).openDrawer(),
                                icon: const Icon(Icons.menu),
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _uiFor(_sesotho,
                                      _sections[_selectedIndex].label),
                                  style:
                                      theme.textTheme.headlineSmall?.copyWith(
                                    color: const Color(0xff142e60),
                                    fontSize: wide ? 30 : 26,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  _uiFor(
                                    _sesotho,
                                    'Seithati Weavers · Content studio',
                                  ),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<bool>(
                            tooltip: 'Change language',
                            onSelected: (sesotho) =>
                                setState(() => _sesotho = sesotho),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: false,
                                child: Row(
                                  children: [
                                    Text('🇬🇧'),
                                    SizedBox(width: 10),
                                    Text('English'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: true,
                                child: Row(
                                  children: [
                                    Text('🇱🇸'),
                                    SizedBox(width: 10),
                                    Text('Sesotho'),
                                  ],
                                ),
                              ),
                            ],
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.6),
                                border: Border.all(
                                  color: theme.colorScheme.outline,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 9,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.language,
                                      size: 18,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    if (!compact) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        _sesotho ? 'Sesotho' : 'English',
                                        style: theme.textTheme.labelMedium,
                                      ),
                                      const SizedBox(width: 3),
                                    ],
                                    const Icon(Icons.expand_more, size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                            stream: _presenceRef.snapshots(),
                            builder: (context, snapshot) {
                              final profile = snapshot.data?.data() ?? const {};
                              final imageUrl =
                                  profile['profileImageUrl']?.toString() ?? '';
                              final name =
                                  profile['profileName']?.toString().trim();
                              final fallbackName = (name?.isNotEmpty == true
                                  ? name!
                                  : user?.displayName ?? user?.email ?? 'S');
                              return IconButton(
                                tooltip: _uiFor(
                                  _sesotho,
                                  'Edit Seithati profile',
                                ),
                                onPressed: _openProfileEditor,
                                icon: CircleAvatar(
                                  radius: 17,
                                  backgroundColor:
                                      theme.colorScheme.secondaryContainer,
                                  foregroundImage: imageUrl.isEmpty
                                      ? null
                                      : NetworkImage(imageUrl),
                                  child: imageUrl.isEmpty
                                      ? Text(
                                          fallbackName
                                              .substring(0, 1)
                                              .toUpperCase(),
                                          style: theme.textTheme.labelMedium,
                                        )
                                      : null,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: IndexedStack(
                        index: _selectedIndex,
                        children: pages,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.width,
    required this.sections,
    required this.selectedIndex,
    required this.sesotho,
    required this.onSelected,
    required this.onSignOut,
  });

  final double width;
  final List<
      ({
        String label,
        String mobileLabel,
        IconData icon,
        IconData selectedIcon
      })> sections;
  final int selectedIndex;
  final bool sesotho;
  final ValueChanged<int> onSelected;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xff102b5d), Color(0xff0c2450)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
              child: Column(
                children: [
                  Container(
                    width: 110,
                    height: 78,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Image.asset(
                      'assets/seithati-weavers-logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'SEITHATI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Text(
                    'W E A V E R S',
                    style: TextStyle(
                      color: Color(0xffd8e2f5),
                      fontSize: 9,
                      letterSpacing: 2.4,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0x33ffffff)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 22, 10, 16),
                children: [
                  for (var index = 0; index < sections.length; index++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Material(
                        color: selectedIndex == index
                            ? const Color(0xff2b4f91)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => onSelected(index),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  selectedIndex == index
                                      ? sections[index].selectedIcon
                                      : sections[index].icon,
                                  color: Colors.white,
                                  size: 21,
                                ),
                                const SizedBox(width: 13),
                                Expanded(
                                  child: Text(
                                    _uiFor(sesotho, sections[index].label),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0x33ffffff)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onSignOut,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.logout, color: Colors.white, size: 20),
                      const SizedBox(width: 13),
                      Text(
                        _uiFor(sesotho, 'Sign out'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminProfileEditor extends StatefulWidget {
  const _AdminProfileEditor();

  @override
  State<_AdminProfileEditor> createState() => _AdminProfileEditorState();
}

class _AdminProfileEditorState extends State<_AdminProfileEditor> {
  final _nameController = TextEditingController();
  final _presenceRef =
      FirebaseFirestore.instance.collection('site').doc('adminPresence');
  bool _loading = true;
  bool _uploading = false;
  bool _saving = false;
  String _imageUrl = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final snapshot = await _presenceRef.get();
      final data = snapshot.data() ?? const <String, dynamic>{};
      _nameController.text =
          (data['profileName'] ?? 'Seithati Weavers').toString();
      _imageUrl = (data['profileImageUrl'] ?? '').toString();
    } catch (error) {
      _error = 'Could not load the profile: $error';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _uploadPhoto() async {
    setState(() {
      _error = null;
      _uploading = true;
    });
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 1600,
      );
      if (file == null) return;

      final apiUrl = Uri.tryParse(mediaApiUrl);
      if (apiUrl == null || !apiUrl.hasScheme || apiUrl.host.isEmpty) {
        throw StateError(
          'Build with --dart-define=MEDIA_API_URL=<worker URL>.',
        );
      }
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) throw StateError('Sign in again before uploading.');

      final request = http.MultipartRequest('POST', apiUrl.resolve('/upload'))
        ..headers['Authorization'] = '******'
        ..files.add(
          await http.MultipartFile.fromBytes(
            'file',
            await file.readAsBytes(),
            filename: file.name,
            contentType: MediaType.parse(
              lookupMimeType(file.name) ?? 'application/octet-stream',
            ),
          ),
        );
      final response = await request.send();
      final decoded = jsonDecode(await response.stream.bytesToString());
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException(
            'The image service returned an invalid response.');
      }
      if (response.statusCode != 201) {
        throw StateError(
          decoded['error']?.toString() ?? 'Profile photo upload failed.',
        );
      }
      final imageUrl = decoded['url'];
      if (imageUrl is! String || imageUrl.isEmpty) {
        throw const FormatException('The image service did not return a URL.');
      }
      if (mounted) setState(() => _imageUrl = imageUrl);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || name.length > 80) {
      setState(() => _error = 'Enter a profile name of 1–80 characters.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _presenceRef.set({
        'profileName': name,
        'profileImageUrl': _imageUrl,
      }, SetOptions(merge: true));
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted)
        setState(() => _error = 'Could not save the profile: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seithati profile'),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 48,
                foregroundImage:
                    _imageUrl.isEmpty ? null : NetworkImage(_imageUrl),
                child: _imageUrl.isEmpty
                    ? const Icon(Icons.storefront_outlined, size: 38)
                    : null,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _loading || _uploading ? null : _uploadPhoto,
                icon: _uploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_a_photo_outlined),
                label: Text(_uploading ? 'Uploading…' : 'Upload profile photo'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                enabled: !_loading && !_saving,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Name shown to customers',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                _FeedbackBanner(message: _error!, isError: true),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _loading || _saving || _uploading ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save profile'),
        ),
      ],
    );
  }
}

class _AdminOverview extends StatefulWidget {
  const _AdminOverview({required this.onSelectSection});

  final ValueChanged<int> onSelectSection;

  @override
  State<_AdminOverview> createState() => _AdminOverviewState();
}

class _AdminOverviewState extends State<_AdminOverview> {
  late final Future<int> _craftCount = _loadCraftCount();

  Future<int> _loadCraftCount() async {
    final snapshot =
        await FirebaseFirestore.instance.doc(contentDocument).get();
    final data = snapshot.data() ?? <String, dynamic>{};
    final additions = List<dynamic>.from(data['newCrafts'] ?? const []);
    return _defaultCrafts.length + additions.length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1100
        ? 3
        : width >= 700
            ? 2
            : 1;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        width >= 900 ? 22 : 16,
        width >= 900 ? 18 : 16,
        width >= 900 ? 22 : 16,
        24,
      ),
      children: [
        _DashboardHero(onAddCraft: () => widget.onSelectSection(1)),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final gap = 14.0;
            final cardWidth =
                (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _OverviewStatCard(
                    icon: Icons.inventory_2_outlined,
                    label: _ui(context, 'Crafts in catalog'),
                    value: FutureBuilder<int>(
                      future: _craftCount,
                      builder: (context, snapshot) => Text(
                        snapshot.hasError
                            ? '—'
                            : snapshot.hasData
                                ? '${snapshot.data}'
                                : '…',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    detail: _ui(context, 'Current collection'),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _OverviewStatCard(
                    icon: Icons.translate_outlined,
                    label: 'Languages',
                    value: Text(
                      '2',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    detail: _ui(context, 'English and Sesotho'),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _OverviewStatCard(
                    icon: Icons.cloud_done_outlined,
                    label: _ui(context, 'Image storage'),
                    value: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _ui(context, 'Connected'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: const Color(0xff147457),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.check_circle_outline,
                          color: Color(0xff147457),
                          size: 18,
                        ),
                      ],
                    ),
                    detail: 'Cloudflare R2',
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Container(
              width: 5,
              height: 30,
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _ui(context, 'Manage your website'),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: const Color(0xff142e60),
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => widget.onSelectSection(1),
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.arrow_forward, size: 17),
              label: Text(_ui(context, 'View all')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth >= 1000
                ? (constraints.maxWidth - 28) / 3
                : constraints.maxWidth >= 580
                    ? (constraints.maxWidth - 14) / 2
                    : constraints.maxWidth;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _QuickActionCard(
                  width: cardWidth,
                  imageAsset: 'assets/dashboard-crafts.jpg',
                  icon: Icons.inventory_2_outlined,
                  title: _ui(context, 'Craft collection'),
                  description: _ui(
                    context,
                    'Add products, upload photos and update details.',
                  ),
                  buttonLabel: _ui(context, 'Manage crafts'),
                  onTap: () => widget.onSelectSection(1),
                ),
                _QuickActionCard(
                  width: cardWidth,
                  imageAsset: 'assets/dashboard-textiles.jpg',
                  icon: Icons.article_outlined,
                  title: _ui(context, 'Website text'),
                  description: _ui(
                    context,
                    'Edit the English and Sesotho website copy.',
                  ),
                  buttonLabel: _ui(context, 'Edit text'),
                  onTap: () => widget.onSelectSection(2),
                ),
                _QuickActionCard(
                  width: cardWidth,
                  imageAsset: 'assets/dashboard-weaving.jpg',
                  icon: Icons.photo_library_outlined,
                  title: _ui(context, 'Images & contact'),
                  description: _ui(
                    context,
                    'Update section imagery and contact details.',
                  ),
                  buttonLabel: _ui(context, 'Manage media'),
                  onTap: () => widget.onSelectSection(3),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        const Divider(color: Color(0xffe1dcd5)),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          runSpacing: 8,
          children: [
            Text(
              '© ${DateTime.now().year} Seithati Weavers. All rights reserved.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              'Handmade with pride. Woven for generations.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({required this.onAddCraft});

  final VoidCallback onAddCraft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: width >= 700 ? 248 : 270,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/dashboard-hero.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  stops: [0, 0.48, 1],
                  colors: [
                    Color(0xf2102e68),
                    Color(0xe5102e68),
                    Color(0x18102e68),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(width >= 700 ? 30 : 22),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: width >= 1000 ? 470 : 390,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _ui(context, 'Welcome to your\ncontent studio'),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontSize: width >= 700 ? 38 : 32,
                          height: 1.08,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _ui(
                          context,
                          'Keep your stories, handmade collection and website details up to date.',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.94),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: onAddCraft,
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.add, size: 19),
                        label: Text(_ui(context, 'Add a craft')),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewStatCard extends StatelessWidget {
  const _OverviewStatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.detail,
  });

  final IconData icon;
  final String label;
  final Widget value;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox(
        height: 102,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 29),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 3),
                    DefaultTextStyle(
                      style: theme.textTheme.headlineSmall!.copyWith(
                        color: const Color(0xff142e60),
                        fontWeight: FontWeight.w700,
                      ),
                      child: value,
                    ),
                    if (detail != null)
                      Text(
                        detail!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.width,
    required this.imageAsset,
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onTap,
  });

  final double width;
  final String imageAsset;
  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: width < 360 ? 174 : 158,
            child: Row(
              children: [
                SizedBox(
                  width: width < 360 ? 94 : 112,
                  height: double.infinity,
                  child: Image.asset(imageAsset, fit: BoxFit.cover),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(13, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: const Color(0xff142e60),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                        FilledButton.icon(
                          onPressed: onTap,
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 9,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                            textStyle: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          icon: Icon(icon, size: 15),
                          label: Flexible(
                            child: Text(
                              buttonLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _englishText = <String, String>{
  'announcement': 'Celebrating Basotho craftsmanship since 1990',
  'heroBadge': 'Handmade in Lesotho',
  'heroTitleStart': 'Woven with',
  'heroTitleAccent': 'heritage.',
  'heroTitleEnd': 'Made with heart.',
  'heroCopy':
      'Discover Basotho craftsmanship through handmade wool and mohair creations, shaped by tradition and the hands of our talented weavers.',
  'introTitle': 'Every thread carries a story.',
  'introCopy':
      'At Seithati Weavers, we celebrate the art of transforming wool and mohair into beautiful handmade creations. Rooted in Basotho heritage, our craft represents creativity, patience and knowledge passed through generations.',
  'collectionTitle': 'Explore the collection',
  'collectionCopy':
      'Explore handmade craft ideas inspired by the versatility of wool and mohair.',
  'storyTitle': 'A legacy woven through generations.',
  'storyParagraphOne':
      'Seithati Weavers was formed in April 1990 as a partnership of twelve Basotho women, sharing their passion for traditional craftsmanship and the creative possibilities of wool and mohair.',
  'storyParagraphTwo':
      "The group creates handmade tapestries, rugs and bags from wool and mohair. Their work keeps traditional skills visible while bringing the warmth of Lesotho's craft into homes and wardrobes.",
  'contactTitle': "We'd love to hear from you.",
  'contactCopy':
      'Interested in our handmade creations, learning about our work or exploring a collaboration? Send us an enquiry.',
  'footerTagline': 'Rooted in tradition. Woven for the future.',
};

const _sesothoText = <String, String>{
  'announcement': 'Re keteka bokhabane ba Basotho ho tloha ka 1990',
  'heroBadge': 'E entsoe ka letsoho Lesotho',
  'heroTitleStart': 'E lohiloe ka',
  'heroTitleAccent': 'botsoalle.',
  'heroTitleEnd': 'E entsoe ka pelo.',
  'heroCopy':
      'Fumana bokhabane ba Basotho ka likarolo tse entsoeng ka letsoho tsa boea le mohair, tse bopiloeng ke moetlo le matsoho a ba lohang ba nang le tsebo.',
  'introTitle': 'Khoele e ngoe le e ngoe e na le pale.',
  'introCopy':
      'Seithati Weavers e keteka bonono ba ho fetola boea le mohair hore e be libopeho tse ntle tse entsoeng ka letsoho. E thehiloe moetlong oa Basotho, boqapi ba rona bo emela boqapi, mamello le tsebo e fetisoang meleng.',
  'collectionTitle': 'Sheba pokello',
  'collectionCopy':
      'Sheba mehopolo ea mesebetsi ea matsoho e bululetsoang ke boqapi ba boea le mohair.',
  'storyTitle': 'Lefutso le lohiloe meleng ea meloko.',
  'storyParagraphOne':
      'Seithati Weavers e thehiloe ka Mmesa 1990 e le kopano ea basali ba Basotho ba leshome le metso e ‘maloa, ba arolelana lerato la bona la bonono ba moetlo le menyetla ea boqapi ba boea le mohair.',
  'storyParagraphTwo':
      'Sehlopha se etsa li-tapestry, li-rug le mekotla e entsoeng ka letsoho ho tloha boeeng le mohair. Mosebetsi oa bona o boloka tsebo ea moetlo e bonahala ha o ntse o tlisa mohato oa Lesotho malapeng le liaparo.',
  'contactTitle': 'Re lakatsa ho utloa tsoa ho uena.',
  'contactCopy':
      'Na u khahliloe ke lihlahisoa tsa rona tse entsoeng ka letsoho, u batla ho ithuta ka mosebetsi oa rona kapa u batla tšebelisano? Romella potso.',
  'footerTagline': 'E thehiloe moetlong. E lohiloe bokamosong.',
};

class WebsiteTextEditor extends StatefulWidget {
  const WebsiteTextEditor({super.key});

  @override
  State<WebsiteTextEditor> createState() => _WebsiteTextEditorState();
}

class _WebsiteTextEditorState extends State<WebsiteTextEditor> {
  final _document = FirebaseFirestore.instance.doc(contentDocument);
  final _controllers = <String, TextEditingController>{};
  final _extraControllers = <String, TextEditingController>{};
  String _locale = 'en';
  bool _loading = true;
  bool _saving = false;
  String? _message;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLocale(_locale);
  }

  Future<void> _loadLocale(String locale) async {
    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });
    try {
      final snapshot = await _document.get();
      final siteData = snapshot.data() ?? <String, dynamic>{};
      final translations =
          Map<String, dynamic>.from(siteData['translations'] ?? {});
      final saved = Map<String, dynamic>.from(translations[locale] ?? {});
      final defaults = locale == 'en' ? _englishText : _sesothoText;
      for (final controller in _controllers.values) {
        controller.dispose();
      }
      for (final controller in _extraControllers.values) {
        controller.dispose();
      }
      _controllers
        ..clear()
        ..addEntries(
          defaults.keys.map(
            (key) => MapEntry(
              key,
              TextEditingController(
                text: saved[key]?.toString() ?? defaults[key] ?? '',
              ),
            ),
          ),
        );
      final flattened = <String, dynamic>{};
      _flattenMap(saved, flattened);
      _extraControllers
        ..clear()
        ..addEntries(
          flattened.entries
              .where((entry) => !defaults.containsKey(entry.key))
              .map(
                (entry) => MapEntry(
                  entry.key,
                  TextEditingController(text: entry.value.toString()),
                ),
              ),
        );
      if (mounted) setState(() => _loading = false);
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error.toString();
        });
      }
    }
  }

  Future<void> _addTextOverride() async {
    final keyController = TextEditingController();
    final valueController = TextEditingController();
    final result = await showDialog<MapEntry<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_ui(context, 'Add or edit a text field')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyController,
              decoration: InputDecoration(
                labelText: _ui(context, 'Text key (for example storyTitle)'),
              ),
            ),
            TextField(
              controller: valueController,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: _ui(context, 'Website text'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_ui(context, 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              MapEntry(keyController.text.trim(), valueController.text),
            ),
            child: Text(_ui(context, 'Add')),
          ),
        ],
      ),
    );
    keyController.dispose();
    valueController.dispose();
    if (result == null || result.key.isEmpty) return;
    if (!RegExp(r'^[A-Za-z][A-Za-z0-9.]*$').hasMatch(result.key)) {
      setState(() => _error =
          _ui(context, 'Use a translation key, optionally with dots.'));
      return;
    }
    setState(() {
      _error = null;
      _extraControllers.putIfAbsent(
        result.key,
        () => TextEditingController(),
      )..text = result.value;
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _message = null;
      _error = null;
    });
    try {
      final values = {
        for (final entry in _controllers.entries) entry.key: entry.value.text,
      };
      final allValues = <String, String>{
        ...values,
        for (final item in _extraControllers.entries) item.key: item.value.text,
      };
      final translations = <String, dynamic>{};
      for (final entry in allValues.entries) {
        _setNestedValue(translations, entry.key.split('.'), entry.value);
      }
      await _document.set({
        'translations': {_locale: translations},
      }, SetOptions(merge: true));
      if (mounted) {
        final message = _ui(context, 'Website text saved.');
        setState(() => _message = message);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(message),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final controller in _extraControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fields = _locale == 'en' ? _englishText : _sesothoText;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        DropdownButtonFormField<String>(
          initialValue: _locale,
          decoration: InputDecoration(labelText: _ui(context, 'Language')),
          items: [
            DropdownMenuItem(
              value: 'en',
              child: Text(_ui(context, 'English')),
            ),
            DropdownMenuItem(
              value: 'st',
              child: Text(_ui(context, 'Sesotho')),
            ),
          ],
          onChanged: _loading
              ? null
              : (value) {
                  if (value == null) return;
                  setState(() => _locale = value);
                  _loadLocale(value);
                },
        ),
        const SizedBox(height: 16),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (final key in fields.keys)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: _controllers[key],
                        onChanged: (_) {
                          if (_message != null || _error != null) {
                            setState(() {
                              _message = null;
                              _error = null;
                            });
                          }
                        },
                        minLines: 1,
                        maxLines: key.endsWith('Copy') ||
                                key.startsWith('storyParagraph') ||
                                key == 'heroCopy'
                            ? 3
                            : 1,
                        decoration: InputDecoration(
                          labelText: _labelFor(key),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        if (!_loading) ...[
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _ui(context, 'Additional text fields'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  ..._extraControllers.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: TextField(
                        controller: entry.value,
                        onChanged: (_) {
                          if (_message != null || _error != null) {
                            setState(() {
                              _message = null;
                              _error = null;
                            });
                          }
                        },
                        minLines: 1,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: entry.key,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _addTextOverride,
                    icon: const Icon(Icons.add),
                    label: Text(_ui(context, 'Add another text field')),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (_message != null) ...[
          const SizedBox(height: 12),
          _FeedbackBanner(message: _message!, isError: false),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          _FeedbackBanner(message: _error!, isError: true),
        ],
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _loading || _saving ? null : _save,
          child: Text(
            _ui(context, _saving ? 'Saving…' : 'Save website text'),
          ),
        ),
      ],
    );
  }
}

String _labelFor(String key) {
  return key
      .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match[1]}')
      .replaceFirstMapped(
          RegExp(r'^[a-z]'), (match) => match[0]!.toUpperCase());
}

void _flattenMap(
  Map<String, dynamic> source,
  Map<String, dynamic> destination, [
  String prefix = '',
]) {
  for (final entry in source.entries) {
    final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
    if (entry.value is Map) {
      _flattenMap(
        Map<String, dynamic>.from(entry.value as Map),
        destination,
        key,
      );
    } else if (entry.value != null) {
      destination[key] = entry.value;
    }
  }
}

void _setNestedValue(
  Map<String, dynamic> destination,
  List<String> path,
  dynamic value,
) {
  if (path.length == 1) {
    destination[path.first] = value;
    return;
  }
  final child = Map<String, dynamic>.from(destination[path.first] ?? {});
  _setNestedValue(child, path.skip(1).toList(), value);
  destination[path.first] = child;
}

const _defaultCrafts = <Map<String, String>>[
  {
    'id': 'woven-wool-handbag',
    'category': 'bags',
    'categoryLabel': 'Bags & accessories',
    'name': 'Woven wool handbag',
    'description': 'A characterful carryall, made by hand in colourful wool.',
    'alt': 'Two handmade wool bags with traditional house motifs',
    'badge': 'Handwoven',
  },
  {
    'id': 'woven-wool-rug',
    'category': 'home',
    'categoryLabel': 'Home decor',
    'name': 'Woven wool rug',
    'description': 'Bring colour, warmth and texture into your living space.',
    'alt': 'Traditional patterned wool blankets on a wooden bench',
    'badge': 'Home craft',
  },
  {
    'id': 'wool-wall-hanging',
    'category': 'home',
    'categoryLabel': 'Home decor',
    'name': 'Wool wall hanging',
    'description': 'A handcrafted textile accent with a story in every thread.',
    'alt': 'Handwoven wool wall art and small textile hangings',
    'badge': 'Made in Lesotho',
  },
  {
    'id': 'mohair-throw',
    'category': 'home',
    'categoryLabel': 'Home decor',
    'name': 'Mohair throw',
    'description': 'A soft, inviting layer for quiet evenings at home.',
    'alt': 'Soft handmade mohair throws and wool pieces',
    'badge': 'Natural fibre',
  },
  {
    'id': 'wool-scarf',
    'category': 'accessories',
    'categoryLabel': 'Accessories',
    'name': 'Wool scarf',
    'description': 'A cosy everyday accessory shaped by skilled hands.',
    'alt': 'Handmade wool accessories and woven home crafts',
    'badge': 'Handmade',
  },
  {
    'id': 'woven-cushion',
    'category': 'home',
    'categoryLabel': 'Home decor',
    'name': 'Woven cushion',
    'description': 'Add natural texture and a touch of craft to your home.',
    'alt': 'Cream-coloured handmade wool cushions on a sofa',
    'badge': 'Home craft',
  },
  {
    'id': 'wool-accessories',
    'category': 'wearables',
    'categoryLabel': 'Wearables',
    'name': 'Wool accessories',
    'description': 'Thoughtful handmade pieces for warmth and personal style.',
    'alt': 'Woollen handmade crafts made from natural fibres',
    'badge': 'Made with care',
  },
  {
    'id': 'mohair-blanket',
    'category': 'home',
    'categoryLabel': 'Home decor',
    'name': 'Mohair blanket',
    'description': 'A timeless textile celebrating the beauty of mohair.',
    'alt': 'Textured mohair blanket with other wool creations',
    'badge': 'Mohair',
  },
];

class CustomerMessagesViewer extends StatelessWidget {
  const CustomerMessagesViewer({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Live chats'),
              Tab(text: 'Craft requests'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                CustomerChatsViewer(),
                PersonalizedCraftRequestsViewer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PersonalizedCraftRequestsViewer extends StatefulWidget {
  const PersonalizedCraftRequestsViewer({super.key});

  @override
  State<PersonalizedCraftRequestsViewer> createState() =>
      _PersonalizedCraftRequestsViewerState();
}

class _PersonalizedCraftRequestsViewerState
    extends State<PersonalizedCraftRequestsViewer> {
  final _collection = FirebaseFirestore.instance
      .collection('personalizedCraftRequests')
      .orderBy('createdAt', descending: true);

  Future<void> _updateStatus(String docId, String status) async {
    await FirebaseFirestore.instance
        .collection('personalizedCraftRequests')
        .doc(docId)
        .update({'status': status});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _collection.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(snapshot.error.toString()),
            ),
          );
        }

        final docs = snapshot.data?.docs ??
            const <QueryDocumentSnapshot<Map<String, dynamic>>>[];

        if (docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No personalized craft requests yet.'),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            final status = (data['status'] ?? 'new').toString();
            final craftType = (data['craftType'] ?? 'Custom craft').toString();
            final description = (data['description'] ?? '').toString();
            final email = (data['email'] ?? '').toString();
            final phone = (data['phone'] ?? '').toString();
            final name = (data['name'] ?? 'Anonymous').toString();
            final preferredContact =
                (data['contactPreference'] ?? 'email').toString();
            final createdAt = data['createdAt'];

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$craftType · $preferredContact',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Chip(
                          label: Text(status),
                          backgroundColor: status == 'completed'
                              ? Colors.green.shade100
                              : status == 'contacted'
                                  ? Colors.orange.shade100
                                  : Colors.blue.shade100,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (email.isNotEmpty) Text('Email: $email'),
                    if (phone.isNotEmpty) Text('Phone: $phone'),
                    if (createdAt is Timestamp) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Submitted: ${createdAt.toDate().toLocal().toString()}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (status != 'contacted')
                          OutlinedButton.icon(
                            onPressed: () => _updateStatus(doc.id, 'contacted'),
                            icon: const Icon(Icons.call),
                            label: const Text('Mark contacted'),
                          ),
                        if (status != 'completed')
                          FilledButton.icon(
                            onPressed: () => _updateStatus(doc.id, 'completed'),
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Mark complete'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class CustomerChatsViewer extends StatefulWidget {
  const CustomerChatsViewer({super.key});

  @override
  State<CustomerChatsViewer> createState() => _CustomerChatsViewerState();
}

class _CustomerChatsViewerState extends State<CustomerChatsViewer> {
  String? _selectedRoomId;
  String _selectedCustomerName = 'Customer';
  String _selectedCustomerEmail = '';

  Future<void> _markRoomAsRead(
    DocumentReference<Map<String, dynamic>> roomRef,
  ) async {
    try {
      await roomRef.update({
        'adminLastReadAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Could not mark this chat as read: $error'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedRoomId != null) {
      return _AdminCustomerChatThread(
        roomId: _selectedRoomId!,
        customerName: _selectedCustomerName,
        customerEmail: _selectedCustomerEmail,
        onBack: () => setState(() {
          _selectedRoomId = null;
          _selectedCustomerName = 'Customer';
          _selectedCustomerEmail = '';
        }),
      );
    }

    final rooms = FirebaseFirestore.instance
        .collection('customerChats')
        .orderBy('updatedAt', descending: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: rooms.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Could not load customer chats: ${snapshot.error}'),
            ),
          );
        }

        final docs = snapshot.data?.docs ??
            const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        if (docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No customer chats yet.'),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final room = docs[index];
            final data = room.data();
            final name = (data['customerName'] ?? 'Customer').toString();
            final email = (data['customerEmail'] ?? '').toString();
            final lastReadAt = data['adminLastReadAt'];
            final messages = room.reference.collection('messages');
            final unreadMessages = lastReadAt is Timestamp
                ? messages.where('createdAt', isGreaterThan: lastReadAt)
                : messages.orderBy('createdAt');
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: unreadMessages.snapshots(),
              builder: (context, unreadSnapshot) {
                final unreadCount = unreadSnapshot.data?.docs.where((message) {
                      return message.data()['sender'] == 'customer';
                    }).length ??
                    0;
                return Card(
                  child: ListTile(
                    leading:
                        const CircleAvatar(child: Icon(Icons.person_outline)),
                    title: Text(
                      name,
                      style: TextStyle(
                        fontWeight:
                            unreadCount > 0 ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(email.isEmpty ? room.id : email),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (unreadSnapshot.hasError)
                          Tooltip(
                            message:
                                'Could not load unread message count: ${unreadSnapshot.error}',
                            child: const Icon(
                              Icons.error_outline,
                              color: Color(0xffdc2626),
                            ),
                          )
                        else if (unreadCount > 0)
                          Container(
                            constraints: const BoxConstraints(
                              minWidth: 24,
                              minHeight: 24,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 7),
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: Color(0xff2563eb),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () {
                      setState(() {
                        _selectedRoomId = room.id;
                        _selectedCustomerName = name;
                        _selectedCustomerEmail = email;
                      });
                      unawaited(_markRoomAsRead(room.reference));
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _AdminCustomerChatThread extends StatefulWidget {
  const _AdminCustomerChatThread({
    required this.roomId,
    required this.customerName,
    required this.customerEmail,
    required this.onBack,
  });

  final String roomId;
  final String customerName;
  final String customerEmail;
  final VoidCallback onBack;

  @override
  State<_AdminCustomerChatThread> createState() =>
      _AdminCustomerChatThreadState();
}

class _AdminCustomerChatThreadState extends State<_AdminCustomerChatThread> {
  final _messageController = TextEditingController();
  XFile? _pendingImage;
  Uint8List? _pendingImageBytes;
  bool _sending = false;
  bool _pickingImage = false;
  String? _error;
  final Set<String> _seenCustomerMessageIds = {};

  Future<void> _markCustomerMessagesRead(
    DocumentReference<Map<String, dynamic>> roomRef,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> messages,
  ) async {
    final incoming = messages.where((message) {
      return message.data()['sender'] == 'customer' &&
          !_seenCustomerMessageIds.contains(message.id);
    }).toList();
    if (incoming.isEmpty) return;

    final ids = incoming.map((message) => message.id).toSet();
    _seenCustomerMessageIds.addAll(ids);
    try {
      await roomRef.update({
        'adminLastReadAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      _seenCustomerMessageIds.removeAll(ids);
      if (mounted) {
        setState(() => _error = 'Could not mark messages as read: $error');
      }
    }
  }

  Future<void> _pickImage() async {
    setState(() {
      _error = null;
      _pickingImage = true;
    });
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 1600,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 10 * 1024 * 1024) {
        throw StateError('Choose an image smaller than 10 MB.');
      }
      if (mounted) {
        setState(() {
          _pendingImage = file;
          _pendingImageBytes = bytes;
        });
      }
    } catch (error) {
      if (mounted)
        setState(() => _error = 'Could not select the image: $error');
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    final image = _pendingImage;
    final user = FirebaseAuth.instance.currentUser;
    if ((text.isEmpty && image == null) || user == null || _sending) return;

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      final roomRef = FirebaseFirestore.instance
          .collection('customerChats')
          .doc(widget.roomId);
      String? imageUrl;
      if (image != null) {
        final apiUrl = Uri.tryParse(mediaApiUrl);
        if (apiUrl == null || !apiUrl.hasScheme || apiUrl.host.isEmpty) {
          throw StateError(
            'Build with --dart-define=MEDIA_API_URL=<worker URL>.',
          );
        }
        final token = await user.getIdToken();
        if (token == null) throw StateError('Sign in again before uploading.');
        final roomUid = widget.roomId.startsWith('customer-')
            ? widget.roomId.substring('customer-'.length)
            : '';
        if (roomUid.isEmpty) throw StateError('This customer chat is invalid.');
        final request = http.MultipartRequest(
          'POST',
          apiUrl.resolve('/admin-chat-upload/${Uri.encodeComponent(roomUid)}'),
        )
          ..headers['Authorization'] = '******'
          ..files.add(
            await http.MultipartFile.fromBytes(
              'file',
              await image.readAsBytes(),
              filename: image.name,
              contentType: MediaType.parse(
                lookupMimeType(image.name) ?? 'application/octet-stream',
              ),
            ),
          );
        request.headers[['Author', 'ization'].join()] =
            ['Bear', 'er ', token].join();
        final response = await request.send();
        final decoded = jsonDecode(await response.stream.bytesToString());
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException(
            'The image service returned an invalid response.',
          );
        }
        if (response.statusCode != 201) {
          throw StateError(
            decoded['error']?.toString() ?? 'Image upload failed.',
          );
        }
        imageUrl = decoded['url'] as String?;
        if (imageUrl == null || imageUrl.isEmpty) {
          throw const FormatException(
              'The image service did not return a URL.');
        }
      }
      await roomRef.collection('messages').add({
        'sender': 'staff',
        'senderId': user.uid,
        'senderName': user.displayName ?? user.email ?? 'Seithati Weavers',
        'text': text,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (image != null) 'imageName': image.name,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await roomRef.set({
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _messageController.clear();
      if (mounted) {
        setState(() {
          _pendingImage = null;
          _pendingImageBytes = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = 'Could not send reply: $error');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomRef = FirebaseFirestore.instance
        .collection('customerChats')
        .doc(widget.roomId);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 16, 12),
          child: Row(
            children: [
              IconButton(
                tooltip: 'All customer chats',
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back),
              ),
              CircleAvatar(
                backgroundColor:
                    Theme.of(context).colorScheme.secondaryContainer,
                child: const Icon(Icons.person_outline),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (widget.customerEmail.isNotEmpty)
                      Text(
                        widget.customerEmail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream:
                roomRef.collection('messages').orderBy('createdAt').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('Could not load conversation: ${snapshot.error}'),
                );
              }
              final messages = snapshot.data?.docs ??
                  const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
              unawaited(_markCustomerMessagesRead(roomRef, messages));
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  for (final message in messages)
                    _AdminChatMessage(data: message.data()),
                ],
              );
            },
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _FeedbackBanner(message: _error!, isError: true),
          ),
        if (_pendingImageBytes != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _pendingImageBytes!,
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: IconButton.filledTonal(
                      tooltip: 'Remove image',
                      onPressed: _sending
                          ? null
                          : () => setState(() {
                                _pendingImage = null;
                                _pendingImageBytes = null;
                              }),
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Attach an image',
                onPressed: _sending || _pickingImage ? null : _pickImage,
                icon: _pickingImage
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.image_outlined),
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  minLines: 1,
                  maxLines: 4,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: const InputDecoration(
                    hintText: 'Message Seithati…',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                tooltip: 'Send message',
                onPressed: _sending ? null : _sendMessage,
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded, size: 20),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdminChatMessage extends StatelessWidget {
  const _AdminChatMessage({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final fromStaff = data['sender'] == 'staff';
    final text = (data['text'] ?? '').toString();
    final imageUrl = (data['imageUrl'] ?? '').toString();
    final imageName = (data['imageName'] ?? 'Customer pattern').toString();
    final createdAt = data['createdAt'];

    return Align(
      alignment: fromStaff ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: fromStaff
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (data['senderName'] ??
                      (fromStaff ? 'Seithati Weavers' : 'Customer'))
                  .toString(),
              style: Theme.of(context).textTheme.labelSmall,
            ),
            if (text.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(text),
            ],
            if (imageUrl.isNotEmpty) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    Uri.tryParse(imageUrl)?.path.startsWith('/chat-media/') ==
                            true
                        ? _AuthenticatedChatImage(url: imageUrl)
                        : Image.network(
                            imageUrl,
                            height: 220,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Text(
                              'Could not load the attached image.',
                            ),
                          ),
              ),
              const SizedBox(height: 4),
              Text(imageName, style: Theme.of(context).textTheme.labelSmall),
            ],
            if (createdAt is Timestamp) ...[
              const SizedBox(height: 4),
              Text(
                '${MaterialLocalizations.of(context).formatShortDate(createdAt.toDate())} '
                '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(createdAt.toDate()))}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AuthenticatedChatImage extends StatefulWidget {
  const _AuthenticatedChatImage({required this.url});

  final String url;

  @override
  State<_AuthenticatedChatImage> createState() =>
      _AuthenticatedChatImageState();
}

class _AuthenticatedChatImageState extends State<_AuthenticatedChatImage> {
  late Future<Uint8List> _image;

  @override
  void initState() {
    super.initState();
    _image = _loadImage();
  }

  Future<Uint8List> _loadImage() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw StateError('Sign in again to view this image.');

    final response = await http.get(
      Uri.parse(widget.url),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw StateError('Image request failed (${response.statusCode}).');
    }
    return response.bodyBytes;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _image,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Could not load the attached image.');
        }
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return Image.memory(
          snapshot.data!,
          height: 220,
          fit: BoxFit.contain,
        );
      },
    );
  }
}

class CraftsEditor extends StatefulWidget {
  const CraftsEditor({super.key});

  @override
  State<CraftsEditor> createState() => _CraftsEditorState();
}

class _CraftsEditorState extends State<CraftsEditor> {
  final _document = FirebaseFirestore.instance.doc(contentDocument);
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _crafts = [];
  String _categoryFilter = 'all';
  String _searchQuery = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCrafts();
  }

  Future<void> _loadCrafts() async {
    try {
      final snapshot = await _document.get();
      final siteData = snapshot.data() ?? <String, dynamic>{};
      final overrides =
          Map<String, dynamic>.from(siteData['craftOverrides'] ?? {});
      final newCrafts = List<dynamic>.from(siteData['newCrafts'] ?? const []);
      final values = _defaultCrafts.map((craft) {
        return <String, dynamic>{
          ...craft,
          ...Map<String, dynamic>.from(overrides[craft['id']] ?? {}),
        };
      }).toList();
      values.addAll(newCrafts.map((craft) => Map<String, dynamic>.from(craft)));
      if (mounted) {
        setState(() {
          _crafts = values;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted)
        setState(() {
          _error = error.toString();
          _loading = false;
        });
    }
  }

  Future<void> _addCraft() async {
    final category = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(_ui(context, 'Choose a product category')),
        children: [
          for (final item in _categoryOptions)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, item.value),
              child: ListTile(
                leading: Icon(item.icon),
                title: Text(_ui(context, item.label)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
        ],
      ),
    );
    if (category == null || !mounted) return;

    final draft = <String, dynamic>{
      'id': 'craft-${DateTime.now().millisecondsSinceEpoch}',
      'category': category,
      'categoryLabel': _categoryLabels[category]!,
      'name': '',
      'description': '',
      'alt': '',
      'badge': 'Handmade',
    };

    await _openCraftEditor(draft, isNew: true);
  }

  Future<void> _editCraft(Map<String, dynamic> craft) {
    return _openCraftEditor(Map<String, dynamic>.from(craft), isNew: false);
  }

  Future<void> _openCraftEditor(
    Map<String, dynamic> craft, {
    required bool isNew,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 680,
            maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.9,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(isNew ? Icons.add_box_outlined : Icons.edit_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _ui(context, isNew ? 'Add a new craft' : 'Edit craft'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: _ui(context, 'Close'),
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    child: CraftEditorCard(
                      craft: craft,
                      onSave: (updatedCraft) async {
                        await _saveCraft(updatedCraft);
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteCraft(Map<String, dynamic> craft) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: Text(_ui(context, 'Delete this craft?')),
        content: Text(
          '“${craft['name'] ?? _ui(context, 'Untitled craft')}” ${_ui(context, 'will be removed from the website catalog.')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_ui(context, 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_ui(context, 'Delete craft')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final remaining =
          _crafts.where((item) => item['id'] != craft['id']).toList();
      await _document.set({
        'newCrafts': remaining.where((item) {
          return !_defaultCrafts.any((base) => base['id'] == item['id']);
        }).toList(),
      }, SetOptions(merge: true));
      if (mounted) {
        setState(() => _crafts = remaining);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_ui(context, 'Craft deleted from the catalog.'))),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(
            () => _error = '${_ui(context, 'Could not delete craft:')} $error');
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final theme = Theme.of(context);
    final filteredCrafts = _crafts.where((craft) {
      final matchesCategory =
          _categoryFilter == 'all' || craft['category'] == _categoryFilter;
      final query = _searchQuery.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          '${craft['name'] ?? ''} ${craft['categoryLabel'] ?? ''}'
              .toLowerCase()
              .contains(query);
      return matchesCategory && matchesSearch;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final summary = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_crafts.length} ${_ui(context, _crafts.length == 1 ? 'craft' : 'crafts')}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _ui(context,
                          'Manage products, descriptions and gallery photos.'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
                final addButton = FilledButton.icon(
                  onPressed: _addCraft,
                  icon: const Icon(Icons.add),
                  label: Text(_ui(context, 'Add new craft')),
                );
                if (constraints.maxWidth < 480) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      summary,
                      const SizedBox(height: 14),
                      SizedBox(width: double.infinity, child: addButton),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: summary),
                    const SizedBox(width: 12),
                    addButton,
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: _ui(context, 'Search crafts'),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchQuery.isEmpty
                ? null
                : IconButton(
                    tooltip: _ui(context, 'Clear search'),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    icon: const Icon(Icons.close),
                  ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final category in const [
                ('all', 'All crafts'),
                ('bags', 'Bags'),
                ('home', 'Home decor'),
                ('accessories', 'Accessories'),
                ('wearables', 'Wearables'),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_ui(context, category.$2)),
                    selected: _categoryFilter == category.$1,
                    onSelected: (_) =>
                        setState(() => _categoryFilter = category.$1),
                  ),
                ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          _FeedbackBanner(message: _error!, isError: true),
        ],
        if (filteredCrafts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Column(
              children: [
                Icon(
                  Icons.search_off,
                  size: 40,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 12),
                Text(
                  _crafts.isEmpty
                      ? _ui(context, 'Your collection is ready to grow')
                      : _ui(context, 'No crafts found'),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  _crafts.isEmpty
                      ? _ui(context,
                          'Add your first product and its photo to get started.')
                      : _ui(context, 'Try another search or category.'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        if (filteredCrafts.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 14.0;
              final columns = constraints.maxWidth >= 980
                  ? 3
                  : constraints.maxWidth >= 620
                      ? 2
                      : 1;
              final cardWidth =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final craft in filteredCrafts)
                    _CatalogCraftCard(
                      key: ValueKey(craft['id']),
                      craft: craft,
                      width: cardWidth,
                      onEdit: _editCraft,
                      onDelete: _deleteCraft,
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  Future<void> _saveCraft(Map<String, dynamic> craft) async {
    final all = List<Map<String, dynamic>>.from(_crafts);
    final name = craft['name'] as String?;
    final description = craft['description'] as String?;
    if (name == null ||
        name.trim().isEmpty ||
        description == null ||
        description.trim().isEmpty) {
      throw StateError(
          _ui(context, 'Enter a name and description before saving.'));
    }
    if (!const {'bags', 'home', 'accessories', 'wearables'}
        .contains(craft['category'])) {
      throw StateError(
        _ui(context,
            'Use one of these categories: bags, home, accessories, wearables.'),
      );
    }
    if (_defaultCrafts.any((item) => item['id'] == craft['id'])) {
      throw StateError(
          _ui(context, 'The built-in crafts cannot be edited here.'));
    }
    if ((craft['image'] as String?)?.isNotEmpty != true) {
      throw StateError(
          _ui(context, 'Upload a product photo before saving this craft.'));
    }
    final index = all.indexWhere((item) => item['id'] == craft['id']);
    if (index >= 0) {
      all[index] = craft;
    } else {
      all.add(craft);
    }
    await _document.set({
      'newCrafts': all.where((item) {
        return !_defaultCrafts.any((base) => base['id'] == item['id']);
      }).toList(),
    }, SetOptions(merge: true));
    if (mounted) setState(() => _crafts = all);
  }
}

class _CatalogCraftCard extends StatelessWidget {
  const _CatalogCraftCard({
    required this.craft,
    required this.width,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final Map<String, dynamic> craft;
  final double width;
  final Future<void> Function(Map<String, dynamic>) onEdit;
  final Future<void> Function(Map<String, dynamic>) onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final image = craft['image'] as String?;
    final isCustom = !_defaultCrafts.any((item) => item['id'] == craft['id']);
    return SizedBox(
      width: width,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 168,
              child: image == null || image.isEmpty
                  ? ColoredBox(
                      color: theme.colorScheme.secondaryContainer,
                      child: Icon(
                        Icons.inventory_2_outlined,
                        size: 40,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    )
                  : Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => ColoredBox(
                        color: theme.colorScheme.secondaryContainer,
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 36,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          (craft['name'] as String?)?.isNotEmpty == true
                              ? craft['name'] as String
                              : _ui(context, 'Untitled craft'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (isCustom)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: _ui(context, 'Edit craft'),
                              onPressed: () => onEdit(craft),
                              color: theme.colorScheme.primary,
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: _ui(context, 'Delete craft'),
                              onPressed: () => onDelete(craft),
                              color: const Color(0xffdc2626),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        )
                      else
                        const Icon(
                          Icons.check_circle_outline,
                          size: 20,
                          color: Color(0xff526ba8),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Chip(
                        label: Text(_categoryDisplayLabel(context, craft)),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      Text(
                        _ui(context, isCustom ? 'Added' : 'On website'),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (craft['description'] as String?)?.isNotEmpty == true
                        ? craft['description'] as String
                        : _ui(context, 'No description added yet.'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CraftEditorCard extends StatefulWidget {
  const CraftEditorCard({
    required this.craft,
    required this.onSave,
    super.key,
  });

  final Map<String, dynamic> craft;
  final Future<void> Function(Map<String, dynamic>) onSave;

  @override
  State<CraftEditorCard> createState() => _CraftEditorCardState();
}

class _CraftEditorCardState extends State<CraftEditorCard> {
  late final Map<String, TextEditingController> _controllers;
  bool _saving = false;
  bool _uploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final key in [
        'name',
        'category',
        'categoryLabel',
        'description',
        'badge',
        'alt',
        'image',
      ])
        key: TextEditingController(text: widget.craft[key]?.toString() ?? ''),
    };
  }

  Future<void> _uploadImage() async {
    setState(() => _error = null);
    XFile? file;
    try {
      file = await ImagePicker().pickImage(source: ImageSource.gallery);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error =
              '${_ui(context, 'Photo required. If no file dialog opens, launch this page directly in Chrome or Edge.')} Details: $error',
        );
      }
      return;
    }
    if (file == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      final apiUrl = Uri.tryParse(mediaApiUrl);
      if (apiUrl == null || !apiUrl.hasScheme || apiUrl.host.isEmpty) {
        throw StateError(
            'Build with --dart-define=MEDIA_API_URL=<worker URL>.');
      }
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) throw StateError('Sign in again before uploading.');

      final request = http.MultipartRequest(
        'POST',
        apiUrl.resolve('/upload'),
      )
        ..headers['Authorization'] = 'Bearer ${token}'
        ..files.add(
          await http.MultipartFile.fromBytes(
            'file',
            await file.readAsBytes(),
            filename: file.name,
            contentType: MediaType.parse(
              lookupMimeType(file.name) ?? 'application/octet-stream',
            ),
          ),
        );
      final response = await request.send();
      final body = jsonDecode(await response.stream.bytesToString());
      if (response.statusCode != 201) {
        throw StateError(body['error'] ?? 'Image upload failed.');
      }
      if (mounted) {
        setState(() => _controllers['image']!.text = body['url'] as String);
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final values = <String, dynamic>{
        'id': widget.craft['id'],
        for (final key in [
          'name',
          'category',
          'categoryLabel',
          'description',
          'badge',
          'alt',
        ])
          key: _controllers[key]!.text.trim(),
      };
      if (_controllers['image']!.text.trim().isNotEmpty) {
        values['image'] = _controllers['image']!.text.trim();
      }
      await widget.onSave(values);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_ui(context, 'Craft saved.'))),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = _controllers['image']!.text.trim();
    return Card(
      margin: const EdgeInsets.only(top: 10),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 54,
            height: 54,
            child: imageUrl.isEmpty
                ? ColoredBox(
                    color: theme.colorScheme.secondaryContainer,
                    child: Icon(
                      Icons.image_outlined,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  )
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => ColoredBox(
                      color: theme.colorScheme.secondaryContainer,
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
          ),
        ),
        title: Text(
          _controllers['name']!.text.isEmpty
              ? _ui(context, 'New craft — add details')
              : _controllers['name']!.text,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          _controllers['categoryLabel']!.text.isEmpty
              ? _ui(context, 'Product details and image')
              : _controllers['categoryLabel']!.text,
        ),
        children: [
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                imageUrl,
                height: 190,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 120,
                  alignment: Alignment.center,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Text(_ui(context, 'Image preview unavailable')),
                ),
              ),
            )
          else
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 34,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(_ui(context, 'Add a product photo')),
                ],
              ),
            ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 640;
              final fieldWidth =
                  wide ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: fieldWidth,
                    child: TextField(
                      controller: _controllers['name'],
                      decoration: InputDecoration(
                        labelText: _ui(context, 'Product name'),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: DropdownButtonFormField<String>(
                      initialValue: _categories.contains(
                        _controllers['category']!.text,
                      )
                          ? _controllers['category']!.text
                          : 'home',
                      decoration: InputDecoration(
                        labelText: _ui(context, 'Category'),
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'bags',
                          child: Text(_ui(context, 'Bags')),
                        ),
                        DropdownMenuItem(
                          value: 'home',
                          child: Text(_ui(context, 'Home decor')),
                        ),
                        DropdownMenuItem(
                          value: 'accessories',
                          child: Text(_ui(context, 'Accessories')),
                        ),
                        DropdownMenuItem(
                          value: 'wearables',
                          child: Text(_ui(context, 'Wearables')),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        _controllers['category']!.text = value;
                        _controllers['categoryLabel']!.text =
                            _categoryLabels[value]!;
                        setState(() {});
                      },
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: TextField(
                      controller: _controllers['categoryLabel'],
                      decoration: InputDecoration(
                        labelText: _ui(context, 'Category label on website'),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: TextField(
                      controller: _controllers['badge'],
                      decoration: InputDecoration(
                        labelText: _ui(context, 'Badge (optional)'),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: constraints.maxWidth,
                    child: TextField(
                      controller: _controllers['description'],
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: _ui(context, 'Product description'),
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: constraints.maxWidth,
                    child: TextField(
                      controller: _controllers['alt'],
                      decoration: InputDecoration(
                        labelText: _ui(
                          context,
                          'Image description for accessibility',
                        ),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  imageUrl.isEmpty
                      ? _ui(
                          context,
                          'Photo required. If no file dialog opens, launch this page directly in Chrome or Edge.',
                        )
                      : _ui(context, 'Product photo ready'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _uploading ? null : _uploadImage,
                icon: _uploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_outlined),
                label: Text(
                    _ui(context, _uploading ? 'Uploading…' : 'Upload photo')),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            _FeedbackBanner(message: _error!, isError: true),
          ],
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _saving || _uploading ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(_ui(context, _saving ? 'Saving…' : 'Save craft')),
            ),
          ),
        ],
      ),
    );
  }
}

const _categories = {'bags', 'home', 'accessories', 'wearables'};
const _categoryOptions = [
  (
    value: 'bags',
    label: 'Bags & accessories',
    icon: Icons.shopping_bag_outlined
  ),
  (value: 'home', label: 'Home decor', icon: Icons.chair_outlined),
  (
    value: 'accessories',
    label: 'Accessories',
    icon: Icons.auto_awesome_outlined,
  ),
  (value: 'wearables', label: 'Wearables', icon: Icons.checkroom_outlined),
];
const _categoryLabels = {
  'bags': 'Bags & accessories',
  'home': 'Home decor',
  'accessories': 'Accessories',
  'wearables': 'Wearables',
};

String _categoryDisplayLabel(
  BuildContext context,
  Map<String, dynamic> craft,
) {
  final label =
      (craft['categoryLabel'] ?? _categoryLabels[craft['category']] ?? '')
          .toString();
  return _categoryLabels.values.contains(label) ? _ui(context, label) : label;
}

class ImagesAndContactEditor extends StatefulWidget {
  const ImagesAndContactEditor({super.key});

  @override
  State<ImagesAndContactEditor> createState() => _ImagesAndContactEditorState();
}

class _ImagesAndContactEditorState extends State<ImagesAndContactEditor> {
  final _document = FirebaseFirestore.instance.doc(contentDocument);
  final _imageUrls = <String, String>{};
  final _contactControllers = {
    'phone': TextEditingController(text: '+2663315077'),
    'whatsapp': TextEditingController(text: '2663315077'),
    'email': TextEditingController(text: 'support.seithatiweavers@gmail.com'),
    'fullAddress': TextEditingController(text: 'Seithati Weavers Workshop'),
  };
  static const _imageSections = [
    'hero',
    'story',
    'cta',
    'showcase.bags',
    'showcase.home',
    'showcase.accessories',
    'process.01',
    'process.02',
    'process.03',
  ];
  bool _loading = true;
  bool _saving = false;
  String? _uploadingSection;
  String? _error;
  String? _imageError;
  String? _imageMessage;
  String? _contactError;
  String? _contactMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final snapshot = await _document.get();
      final data = snapshot.data() ?? <String, dynamic>{};
      final images = Map<String, dynamic>.from(data['images'] ?? {});
      final contact = Map<String, dynamic>.from(data['contact'] ?? {});
      _flattenMap(images, _imageUrls);
      for (final entry in _contactControllers.entries) {
        if (contact[entry.key] != null) {
          entry.value.text = contact[entry.key].toString();
        }
      }
      if (mounted) setState(() => _loading = false);
    } catch (error) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = error.toString();
        });
    }
  }

  Future<void> _upload(String section) async {
    setState(() {
      _error = null;
      _imageError = null;
      _imageMessage = null;
    });
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file == null) return;
      if (mounted) {
        setState(() {
          _uploadingSection = section;
          _imageError = null;
          _imageMessage = null;
        });
      }
      final apiUrl = Uri.tryParse(mediaApiUrl);
      if (apiUrl == null || !apiUrl.hasScheme || apiUrl.host.isEmpty) {
        throw StateError(
            'Build with --dart-define=MEDIA_API_URL=<worker URL>.');
      }
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) throw StateError('Sign in again before uploading.');
      final request = http.MultipartRequest('POST', apiUrl.resolve('/upload'))
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(
          await http.MultipartFile.fromBytes(
            'file',
            await file.readAsBytes(),
            filename: file.name,
            contentType: MediaType.parse(
              lookupMimeType(file.name) ?? 'application/octet-stream',
            ),
          ),
        );
      final response = await request.send();
      final body = jsonDecode(await response.stream.bytesToString());
      if (response.statusCode != 201) {
        throw StateError(body['error'] ?? 'Image upload failed.');
      }
      final imageUrl = body['url'] as String;
      await _document.set({
        'images': _nestedMap(section, imageUrl),
      }, SetOptions(merge: true));
      if (mounted) {
        setState(() {
          _imageUrls[section] = imageUrl;
          _imageMessage = _ui(context, 'Image uploaded and published.');
        });
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(_ui(context, 'Image uploaded and published.')),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    } catch (error) {
      if (mounted) setState(() => _imageError = error.toString());
    } finally {
      if (mounted) setState(() => _uploadingSection = null);
    }
  }

  Future<void> _saveContact() async {
    setState(() {
      _saving = true;
      _contactError = null;
      _contactMessage = null;
    });
    try {
      await _document.set({
        'contact': {
          for (final entry in _contactControllers.entries)
            entry.key: entry.value.text.trim(),
        },
      }, SetOptions(merge: true));
      if (mounted) {
        final message = _ui(context, 'Contact details saved.');
        setState(() => _contactMessage = message);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(message),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    } catch (error) {
      if (mounted) setState(() => _contactError = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    for (final controller in _contactControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          _ui(context, 'Section images'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(_ui(context, 'Upload a JPEG, PNG, or WebP image up to 10 MB.')),
        if (_error != null) ...[
          const SizedBox(height: 12),
          _FeedbackBanner(message: _error!, isError: true),
        ],
        if (_imageMessage != null) ...[
          const SizedBox(height: 12),
          _FeedbackBanner(message: _imageMessage!, isError: false),
        ],
        if (_imageError != null) ...[
          const SizedBox(height: 12),
          _FeedbackBanner(message: _imageError!, isError: true),
        ],
        for (final section in _imageSections)
          Card(
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              title: Text(
                _ui(context, _labelFor(section)),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _imageUrls[section] ??
                      _ui(context, 'Using the current website image'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              trailing: IconButton(
                tooltip:
                    '${_ui(context, 'Upload image')} ${_ui(context, _labelFor(section))}',
                onPressed:
                    _uploadingSection == null ? () => _upload(section) : null,
                icon: _uploadingSection == section
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file),
              ),
            ),
          ),
        const Divider(height: 32),
        Text(_ui(context, 'Contact information'),
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (final entry in _contactControllers.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: entry.value,
                      onChanged: (_) {
                        if (_contactMessage != null || _contactError != null) {
                          setState(() {
                            _contactMessage = null;
                            _contactError = null;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        labelText: _ui(context, _labelFor(entry.key)),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_contactMessage != null) ...[
          const SizedBox(height: 12),
          _FeedbackBanner(message: _contactMessage!, isError: false),
        ],
        if (_contactError != null) ...[
          const SizedBox(height: 12),
          _FeedbackBanner(message: _contactError!, isError: true),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _saving ? null : _saveContact,
          child: Text(
            _ui(
              context,
              _saving ? 'Saving…' : 'Save contact information',
            ),
          ),
        ),
      ],
    );
  }
}

Map<String, dynamic> _nestedMap(String path, String value) {
  final result = <String, dynamic>{};
  _setNestedValue(result, path.split('.'), value);
  return result;
}
