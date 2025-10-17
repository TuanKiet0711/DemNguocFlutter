// import 'package:flutter/material.dart';
// import '../i18n/app_localizations.dart';
// import '../language_controller.dart';
// import 'language_picker_sheet.dart';

// class LanguageButton extends StatelessWidget {
//   const LanguageButton({super.key, this.iconColor = Colors.white});
//   final Color iconColor;

//   @override
//   Widget build(BuildContext context) {
//     final loc = AppLoc.of(context);
//     return IconButton(
//       tooltip: loc.language,
//       icon: Icon(Icons.language, color: iconColor),
//       onPressed: () async {
//         await showModalBottomSheet(
//           context: context,
//           showDragHandle: true,
//           shape: const RoundedRectangleBorder(
//             borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//           ),
//           builder: (_) => const LanguagePickerSheet(),
//         );
//         // Không cần làm gì thêm: LanguageController.I.setLocale() sẽ notify và MaterialApp rebuild
//       },
//     );
//   }
// }
