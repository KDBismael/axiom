import 'package:flutter/material.dart';

import '../../../core/widgets/sheets/app_bottom_sheet.dart';
import '../widgets/manage_allies_sheet.dart';

/// Deep-link landing spot for ally-related notifications
/// (ally_removed/accepted/declined — see `notificationTarget`): opens
/// [ManageAlliesSheet] as soon as it mounts and pops itself once the sheet
/// closes. The in-app entry point (Profile's "Gérer mes alliés" row) opens
/// the sheet directly instead, without this intermediate route.
class ManageAlliesSheetRoute extends StatefulWidget {
  const ManageAlliesSheetRoute({super.key});

  @override
  State<ManageAlliesSheetRoute> createState() => _ManageAlliesSheetRouteState();
}

class _ManageAlliesSheetRouteState extends State<ManageAlliesSheetRoute> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await showAppBottomSheet(context, builder: (_) => const ManageAlliesSheet());
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SizedBox.shrink());
  }
}
