// import 'package:flutter/material.dart';
// import '../i18n/app_localizations.dart';
// import '../language_controller.dart';

// class LanguagePickerSheet extends StatefulWidget {
//   const LanguagePickerSheet({super.key});

//   @override
//   State<LanguagePickerSheet> createState() => _LanguagePickerSheetState();
// }

// class _LanguagePickerSheetState extends State<LanguagePickerSheet> {
//   late String _selected;

//   @override
//   void initState() {
//     super.initState();
//     _selected = LanguageController.I.locale.languageCode; // 'vi' | 'en'
//   }

//   @override
//   Widget build(BuildContext context) {
//     final loc = AppLoc.of(context);

//     return SafeArea(
//       child: Padding(
//         padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               loc.pickLanguage,
//               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
//             ),
//             const SizedBox(height: 8),
//             RadioListTile<String>(
//               value: 'vi',
//               groupValue: _selected,
//               title: Text(loc.vietnamese),
//               onChanged: (v) => setState(() => _selected = v!),
//             ),
//             RadioListTile<String>(
//               value: 'en',
//               groupValue: _selected,
//               title: Text(loc.english),
//               onChanged: (v) => setState(() => _selected = v!),
//             ),
//             const SizedBox(height: 8),
//             SizedBox(
//               width: double.infinity,
//               child: FilledButton(
//                 onPressed: () async {
//                   await LanguageController.I.setLocale(Locale(_selected)); // 🔄 đổi toàn app
//                   if (context.mounted) Navigator.pop(context);
//                 },
//                 child: Text(loc.apply),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
