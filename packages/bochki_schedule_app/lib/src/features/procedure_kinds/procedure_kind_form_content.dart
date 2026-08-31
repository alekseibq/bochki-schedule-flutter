import 'package:flutter/material.dart';

import '../../domain/procedure_kinds/procedure_kind.dart';
import 'procedure_kind_dialog.dart';
import 'procedure_kinds_view_model.dart';

/// Reusable procedure form. Its host decides whether it is a dialog or a
/// separate desktop window by supplying the surrounding chrome.
class ProcedureKindFormContent extends StatelessWidget {
  const ProcedureKindFormContent({
    required this.viewModel,
    required this.procedureKinds,
    this.initialProcedureKind,
    this.onSaved,
    this.onCancel,
    super.key,
  });

  final ProcedureKindsViewModel viewModel;
  final List<ProcedureKind> procedureKinds;
  final ProcedureKind? initialProcedureKind;
  final Future<void> Function(ProcedureKind procedureKind)? onSaved;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) => ProcedureKindDialog(
        viewModel: viewModel,
        procedureKinds: procedureKinds,
        initialProcedureKind: initialProcedureKind,
        onSaved: onSaved,
        onCancel: onCancel,
      );
}
