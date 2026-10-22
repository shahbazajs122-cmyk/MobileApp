import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

const purple = Color(0xFF7137B5);
const adminUid = String.fromEnvironment('ADMIN_UID');
const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
const appId = String.fromEnvironment('FIREBASE_APP_ID');
const senderId = String.fromEnvironment('FIREBASE_SENDER_ID');
const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
const storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
const whatsapp = '923161454152';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if ([apiKey, appId, senderId, projectId, adminUid].any((s) => s.isEmpty)) {
    runApp(const MaterialApp(home: Scaffold(body: Center(child: Text('Firebase configuration required. See README.md.')))));
    return;
  }
  await Firebase.initializeApp(options: FirebaseOptions(apiKey: apiKey, appId: appId, messagingSenderId: senderId, projectId: projectId, storageBucket: storageBucket));
  runApp(const ClinicApp());
}
class ClinicApp extends StatefulWidget {
  const ClinicApp({super.key});
  @override State<ClinicApp> createState() => _ClinicAppState();
}
class _ClinicAppState extends State<ClinicApp> {
  bool urdu = false;
  @override Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Dr. Samavia – Clinical Psychologist',
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: purple), scaffoldBackgroundColor: const Color(0xFFFBF8FF), appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFFBF8FF))),
    locale: Locale(urdu ? 'ur' : 'en'),
    supportedLocales: const [Locale('en'), Locale('ur')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates.toList()..addAll([GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate]),
    home: Home(urdu: urdu, toggle: () => setState(() => urdu = !urdu)),
  );
}
class Home extends StatelessWidget {
  final bool urdu; final VoidCallback toggle;
  const Home({super.key, required this.urdu, required this.toggle});
  String t(String en, String ur) => urdu ? ur : en;
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(actions: [TextButton.icon(onPressed: toggle, icon: const Icon(Icons.language), label: Text(urdu ? 'English' : 'اردو')), IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminLogin())), icon: const Icon(Icons.admin_panel_settings_outlined), tooltip: 'Admin')]),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const SizedBox(height: 20), const CircleAvatar(radius: 42, backgroundColor: Color(0xFFE9DAFA), child: Icon(Icons.psychology_alt_outlined, color: purple, size: 54)),
      const SizedBox(height: 12), const Center(child: Text('Dr. Samavia', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: purple))),
      const Center(child: Text('Clinical Psychologist', style: TextStyle(fontSize: 17))),
      const SizedBox(height: 24), Text(t('Book your appointment', 'اپنی اپائنٹمنٹ بک کریں'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12), bookingCard(context, true), const SizedBox(height: 12), bookingCard(context, false),
      const SizedBox(height: 24), Center(child: Text(t('Better Mind • Healthier Life', 'بہتر ذہن • صحت مند زندگی'), style: const TextStyle(color: purple))),
    ]),
  );
  Widget bookingCard(BuildContext context, bool online) => Card(elevation: 1, child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(online ? Icons.phone_in_talk : Icons.local_hospital_outlined, color: purple, size: 34), const SizedBox(height: 8),
    Text(online ? t('Online Booking', 'آن لائن بکنگ') : t('Physical Hospital Booking', 'ہسپتال میں بکنگ'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19)),
    Text(online ? t('WhatsApp voice consultation', 'واٹس ایپ وائس مشاورت') : 'Arshad General Hospital, Bijligar Road, Mardan'),
    const SizedBox(height: 8), Text('PKR ${online ? '2,000' : '1,000'}', style: const TextStyle(color: purple, fontSize: 23, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8), FilledButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Booking(online: online, urdu: urdu))), child: Text(t('Book Now', 'بکنگ کریں'))),
  ])));
}
class Booking extends StatefulWidget {
  final bool online, urdu; const Booking({super.key, required this.online, required this.urdu});
  @override State<Booking> createState() => _BookingState();
}
class _BookingState extends State<Booking> {
  final form = GlobalKey<FormState>(); final name = TextEditingController(); final mobile = TextEditingController(); bool busy = false; String? bookingId;
  String t(String en, String ur) => widget.urdu ? ur : en;
  @override void dispose() {name.dispose(); mobile.dispose(); super.dispose();}
  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      // Anonymous identity permits client creation only; Firestore rules restrict admin reads/updates.
      if (FirebaseAuth.instance.currentUser == null) await FirebaseAuth.instance.signInAnonymously();
      final doc = await FirebaseFirestore.instance.collection('bookings').add({
        'name': name.text.trim(), 'mobile': mobile.text.trim(), 'type': widget.online ? 'online' : 'physical',
        'fee': widget.online ? 2000 : 1000, 'status': 'pending', 'createdAt': FieldValue.serverTimestamp(),
        'ownerUid': FirebaseAuth.instance.currentUser!.uid,
      });
      if (mounted) setState(() => bookingId = doc.id);
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking failed: $e'))); }
    finally {if (mounted) setState(() => busy = false);}
  }
  Future<void> openWhatsApp() async {
    final message = Uri.encodeComponent('Assalamualaikum, I have paid for my ${widget.online ? 'online' : 'physical'} appointment. Booking ID: ${bookingId ?? 'not available'}. I will attach my payment receipt here.');
    final uri = Uri.parse('https://wa.me/$whatsapp?text=$message');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open WhatsApp')));
  }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(t('Booking Request', 'بکنگ کی درخواست'))), body: ListView(padding: const EdgeInsets.all(20), children: [
    Text(widget.online ? t('Online Consultation • PKR 2,000', 'آن لائن مشاورت • ۲۰۰۰ روپے') : t('Physical Consultation • PKR 1,000', 'ہسپتال میں مشاورت • ۱۰۰۰ روپے'), style: const TextStyle(fontSize: 21, color: purple, fontWeight: FontWeight.bold)),
    const SizedBox(height: 16), if (bookingId == null) Form(key: form, child: Column(children: [
      TextFormField(controller: name, decoration: InputDecoration(labelText: t('Full Name', 'مکمل نام'), border: const OutlineInputBorder()), validator: (v) => v == null || v.trim().length < 2 ? 'Enter your name' : null),
      const SizedBox(height: 12), TextFormField(controller: mobile, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: t('Mobile / WhatsApp Number', 'موبائل / واٹس ایپ نمبر'), border: const OutlineInputBorder()), validator: (v) => v == null || !RegExp(r'^\+?[0-9\s-]{10,16}$').hasMatch(v.trim()) ? 'Enter a valid phone number' : null),
      const SizedBox(height: 16), FilledButton(onPressed: busy ? null : submit, child: Text(busy ? 'Sending...' : t('Send Booking Request', 'بکنگ کی درخواست بھیجیں'))),
    ])) else Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [const Icon(Icons.check_circle, color: purple, size: 44), Text(t('Request submitted. Admin will decide your appointment time.', 'درخواست موصول ہوگئی۔ ایڈمن وقت مقرر کرے گا۔')), SelectableText('Booking ID: $bookingId')]))),
    const SizedBox(height: 22), Text(t('Payment methods (display only)', 'ادائیگی کے طریقے (صرف معلومات)'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    const Card(child: ListTile(leading: Icon(Icons.account_balance_wallet_outlined, color: purple), title: Text('Easypaisa'), subtitle: Text('0316 1454152'))),
    const Card(child: ListTile(leading: Icon(Icons.account_balance, color: purple), title: Text('Meezan Bank'), subtitle: Text('Account details to be configured by admin'))),
    const SizedBox(height: 12), FilledButton.icon(onPressed: bookingId == null ? null : openWhatsApp, icon: const Icon(Icons.chat), label: Text(t('Send Payment Receipt on WhatsApp', 'واٹس ایپ پر ادائیگی کی رسید بھیجیں'))),
    const SizedBox(height: 6), Text(t('After payment, attach your receipt in WhatsApp. No receipt is uploaded in this app.', 'ادائیگی کے بعد رسید واٹس ایپ پر بھیجیں۔ ایپ میں رسید اپ لوڈ نہیں ہوتی۔')),
  ]));
}
class AdminLogin extends StatefulWidget {const AdminLogin({super.key}); @override State<AdminLogin> createState() => _AdminLoginState();}
class _AdminLoginState extends State<AdminLogin> {
  final email = TextEditingController(), password = TextEditingController(); bool busy = false;
  @override void dispose(){email.dispose();password.dispose();super.dispose();}
  Future<void> login() async {setState(() => busy = true); try {
    final result = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email.text.trim(), password: password.text);
    if (result.user?.uid != adminUid) {await FirebaseAuth.instance.signOut(); throw Exception('Not an authorized administrator');}
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
  } catch(e) {if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed: $e')));} finally {if(mounted) setState(() => busy = false);}}
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Admin Login')), body: ListView(padding: const EdgeInsets.all(24), children: [const Icon(Icons.admin_panel_settings, color: purple, size: 70), const SizedBox(height: 24), TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Admin email', border: OutlineInputBorder())), const SizedBox(height: 12), TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())), const SizedBox(height: 16), FilledButton(onPressed: busy ? null : login, child: Text(busy ? 'Signing in...' : 'Login'))]));
}
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});
  bool get authorized => FirebaseAuth.instance.currentUser?.uid == adminUid;
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Admin Dashboard'), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () async {await FirebaseAuth.instance.signOut(); if(context.mounted) Navigator.pop(context);})]), body: !authorized ? const Center(child: Text('Unauthorized')) : ListView(padding: const EdgeInsets.all(16), children: [
    const Text('Incoming bookings & client history', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: purple)),
    StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(stream: FirebaseFirestore.instance.collection('bookings').orderBy('createdAt', descending: true).snapshots(), builder: (context, snap) {
      if(snap.hasError) return Text('Could not load bookings: ${snap.error}'); if(!snap.hasData) return const Center(child: CircularProgressIndicator());
      if(snap.data!.docs.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Text('No bookings yet.'));
      return Column(children: snap.data!.docs.map((doc) {final b = doc.data(); return Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${b['name'] ?? ''} • ${b['type'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)), Text('${b['mobile'] ?? ''} • PKR ${b['fee'] ?? ''}'), Text('Status: ${b['status'] ?? ''}'), if(b['appointmentAt'] != null) Text('Appointment: ${b['appointmentAt']}'),
        Wrap(spacing: 8, children: [TextButton(onPressed: () => updateStatus(context, doc.id, 'confirmed'), child: const Text('Confirm / Set time')), TextButton(onPressed: () => updateStatus(context, doc.id, 'rejected'), child: const Text('Reject'))]),
      ])));}).toList());
    }),
    const Divider(), ListTile(leading: const Icon(Icons.person_outline), title: const Text('Edit profile name'), onTap: () => editProfile(context)),
    ListTile(leading: const Icon(Icons.lock_outline), title: const Text('Change password'), onTap: () => changePassword(context)),
  ]));
  Future<void> updateStatus(BuildContext context, String id, String status) async {
    final ctrl = TextEditingController();
    final time = status == 'confirmed' ? await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365))) : null;
    if(status == 'confirmed' && time == null) return;
    TimeOfDay? clock;
    if(status == 'confirmed') {if(!context.mounted) return; clock = await showTimePicker(context: context, initialTime: TimeOfDay.now()); if(clock == null) return;}
    final data = <String,dynamic>{'status': status, 'updatedAt': FieldValue.serverTimestamp()};
    if(time != null && clock != null) data['appointmentAt'] = Timestamp.fromDate(DateTime(time.year, time.month, time.day, clock.hour, clock.minute));
    try {await FirebaseFirestore.instance.collection('bookings').doc(id).update(data);} catch(e) {if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));} ctrl.dispose();
  }
  Future<void> editProfile(BuildContext context) async {final ctrl = TextEditingController(text: FirebaseAuth.instance.currentUser?.displayName); final name = await showDialog<String>(context: context, builder: (c) => AlertDialog(title: const Text('Edit profile'), content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Display name')), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(c, ctrl.text.trim()), child: const Text('Save'))])); if(name != null && name.isNotEmpty) {try {await FirebaseAuth.instance.currentUser!.updateDisplayName(name);} catch(e) {if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));}} ctrl.dispose();}
  Future<void> changePassword(BuildContext context) async {final old = TextEditingController(), next = TextEditingController(); final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Change password'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: old, obscureText: true, decoration: const InputDecoration(labelText: 'Current password')), TextField(controller: next, obscureText: true, decoration: const InputDecoration(labelText: 'New password (6+ characters)'))]), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Update'))])); if(ok == true) {try {final u = FirebaseAuth.instance.currentUser!; await u.reauthenticateWithCredential(EmailAuthProvider.credential(email: u.email!, password: old.text)); await u.updatePassword(next.text); if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated')));} catch(e) {if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));}} old.dispose(); next.dispose();}
}
