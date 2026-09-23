import 'package:flutter/material.dart';

import '../../home/domain/social_worker_case.dart';
import 'case_details_screen.dart';

extension OpenCaseDetails on SocialWorkerCase {
  void openDetails(BuildContext context, {int initialTabIndex = 0}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CaseDetailsScreen(
          caseId: id,
          personName: personName,
          displayId: displayId,
          priority: priority,
          initialTabIndex: initialTabIndex,
        ),
      ),
    );
  }
}
