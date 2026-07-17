import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/features/employees/controllers/employee_controller.dart';
import '../core/features/employees/data/models/employee_model.dart';
import '../core/features/subTasks/controllers/sub_task_controller.dart';

const _primaryColor = Color(0xFF0A0258);
const _accentColor = Color(0xFF4A4A4A);
const _labelColor = Color(0xFF797979);
const _greenOn = Color(0xFF1DC230);

InputDecoration _subtaskFieldDecoration(String hint) => InputDecoration(
  isDense: true,
  hintText: hint,
  hintStyle: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFFB8BEC5)),
  filled: true,
  fillColor: const Color(0xFFF9FAFC),
  contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8.r),
    borderSide: const BorderSide(color: Color(0xFFD9DEE5)),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8.r),
    borderSide: const BorderSide(color: Color(0xFFD9DEE5)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8.r),
    borderSide: const BorderSide(color: Color(0xFF0A0258)),
  ),
);

String? _employeeNameById(EmployeeController employeeController, String id) {
  for (final employee in employeeController.allEmployees) {
    if (employee.id == id) {
      final name = employee.fullName;
      if (name.isNotEmpty) return name;
    }
  }
  return null;
}

/// Simple multi-select bottom sheet for the create-subtask form's
/// assignees. Returns the confirmed selection, or null if dismissed
/// without confirming.
Future<List<String>?> _pickSubtaskAssignees({
  required BuildContext context,
  required EmployeeController employeeController,
  required List<String> currentSelected,
}) async {
  List<String> tempSelected = List.from(currentSelected);
  List<EmployeeModel> filtered = List.from(employeeController.allEmployees);
  final searchCtrl = TextEditingController();

  return showModalBottomSheet<List<String>>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (_) => StatefulBuilder(
      builder: (ctx, ss) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.75,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36.w,
                    height: 4.h,
                    margin: EdgeInsets.symmetric(vertical: 10.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9DEE5),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Assignees',
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: _primaryColor,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Icon(
                          Icons.close,
                          size: 20.r,
                          color: _labelColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: TextField(
                    controller: searchCtrl,
                    style: GoogleFonts.inter(fontSize: 12.sp),
                    decoration: _subtaskFieldDecoration('Search employees')
                        .copyWith(
                          prefixIcon: Icon(
                            CupertinoIcons.search,
                            size: 16.r,
                            color: const Color(0xFF9AA0AB),
                          ),
                        ),
                    onChanged: (q) => ss(() {
                      final query = q.trim().toLowerCase();
                      filtered = query.isEmpty
                          ? List.from(employeeController.allEmployees)
                          : employeeController.allEmployees
                                .where(
                                  (e) =>
                                      e.fullName.toLowerCase().contains(query),
                                )
                                .toList();
                    }),
                  ),
                ),
                SizedBox(height: 8.h),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final emp = filtered[i];
                      final id = emp.id ?? '';
                      final isSelected = tempSelected.contains(id);
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (v) => ss(() {
                          if (v == true) {
                            tempSelected.add(id);
                          } else {
                            tempSelected.remove(id);
                          }
                        }),
                        title: Text(
                          emp.fullName,
                          style: GoogleFonts.inter(fontSize: 13.sp),
                        ),
                        activeColor: _primaryColor,
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, tempSelected),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                      ),
                      child: Text(
                        'Confirm (${tempSelected.length})',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
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

/// Reusable "Create Subtask" bottom sheet — the single implementation
/// behind both `MyTaskDetails.dart`'s Subtasks section and
/// `WorkflowDetailScreen.dart`'s "Add Event" button, so both stay in sync.
/// [onCreated] fires after a successful create (post-refetch), for the
/// caller to `setState`/refresh its own view of the subtask list.
void openCreateSubtaskDialog({
  required BuildContext context,
  required String instanceId,
  required SubTaskController subTaskController,
  required EmployeeController employeeController,
  VoidCallback? onCreated,
}) {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  List<String> selectedAssigneeIds = [];
  TimeOfDay? selectedTime;
  String updateScope = 'single';
  bool isSubmitting = false;
  String? formError;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: StatefulBuilder(
        builder: (ctx, ss) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 24.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Create Subtask',
                      style: GoogleFonts.inter(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: _primaryColor,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Icon(Icons.close, size: 20.r, color: _labelColor),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                if (formError != null) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(
                      formError!,
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                ],
                Text(
                  'Title',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: _labelColor,
                  ),
                ),
                SizedBox(height: 6.h),
                TextField(
                  controller: titleCtrl,
                  style: GoogleFonts.inter(fontSize: 12.sp),
                  decoration: _subtaskFieldDecoration('Enter subtask title'),
                ),
                SizedBox(height: 12.h),
                Text(
                  'Description',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: _labelColor,
                  ),
                ),
                SizedBox(height: 6.h),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  style: GoogleFonts.inter(fontSize: 12.sp),
                  decoration: _subtaskFieldDecoration(
                    'Enter description (optional)',
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'Assignees',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: _labelColor,
                  ),
                ),
                SizedBox(height: 6.h),
                GestureDetector(
                  onTap: () async {
                    final result = await _pickSubtaskAssignees(
                      context: ctx,
                      employeeController: employeeController,
                      currentSelected: selectedAssigneeIds,
                    );
                    if (result != null) {
                      ss(() => selectedAssigneeIds = result);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFC),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: const Color(0xFFD9DEE5)),
                    ),
                    child: Text(
                      selectedAssigneeIds.isEmpty
                          ? 'Select assignees (optional)'
                          : selectedAssigneeIds
                                .map(
                                  (id) =>
                                      _employeeNameById(
                                        employeeController,
                                        id,
                                      ) ??
                                      'Unknown',
                                )
                                .join(', '),
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: selectedAssigneeIds.isEmpty
                            ? const Color(0xFFB8BEC5)
                            : _accentColor,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'Reporting Time',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: _labelColor,
                  ),
                ),
                SizedBox(height: 6.h),
                GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: ctx,
                      initialTime: selectedTime ?? TimeOfDay.now(),
                    );
                    if (picked != null) ss(() => selectedTime = picked);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFC),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: const Color(0xFFD9DEE5)),
                    ),
                    child: Text(
                      selectedTime == null
                          ? 'Select time (optional)'
                          : selectedTime!.format(ctx),
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: selectedTime == null
                            ? const Color(0xFFB8BEC5)
                            : _accentColor,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'Choose Update Option',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: _labelColor,
                  ),
                ),
                RadioListTile<String>(
                  value: 'single',
                  groupValue: updateScope,
                  onChanged: (v) => ss(() => updateScope = v!),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  activeColor: _primaryColor,
                  title: Text(
                    'Only this subtask',
                    style: GoogleFonts.inter(
                      fontSize: 12.5.sp,
                      color: _accentColor,
                    ),
                  ),
                ),
                RadioListTile<String>(
                  value: 'following',
                  groupValue: updateScope,
                  onChanged: (v) => ss(() => updateScope = v!),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  activeColor: _primaryColor,
                  title: Text(
                    'This and all future subtasks',
                    style: GoogleFonts.inter(
                      fontSize: 12.5.sp,
                      color: _accentColor,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD96CFF), Color(0xFF5CE1E6)],
                      ),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8.r),
                        onTap: isSubmitting
                            ? null
                            : () async {
                                final title = titleCtrl.text.trim();
                                if (title.isEmpty) {
                                  ss(
                                    () => formError = 'Please enter a title.',
                                  );
                                  return;
                                }
                                ss(() {
                                  formError = null;
                                  isSubmitting = true;
                                });

                                String? time;
                                String? period;
                                if (selectedTime != null) {
                                  final hour12 =
                                      selectedTime!.hourOfPeriod == 0
                                      ? 12
                                      : selectedTime!.hourOfPeriod;
                                  time =
                                      '${hour12.toString().padLeft(2, '0')}:'
                                      '${selectedTime!.minute.toString().padLeft(2, '0')}';
                                  period = selectedTime!.period == DayPeriod.am
                                      ? 'AM'
                                      : 'PM';
                                }

                                final success = await subTaskController
                                    .handleCreateSubTask(
                                      instanceId: instanceId,
                                      title: title,
                                      description:
                                          descCtrl.text.trim().isEmpty
                                          ? null
                                          : descCtrl.text.trim(),
                                      assigneeIds: selectedAssigneeIds.isEmpty
                                          ? null
                                          : selectedAssigneeIds,
                                      time: time,
                                      period: period,
                                      scope: updateScope,
                                    );

                                if (!ctx.mounted) return;

                                if (success) {
                                  Navigator.pop(ctx);
                                  await subTaskController
                                      .handleGetAllSubTaskInstances(
                                        instanceId: instanceId,
                                      );
                                  if (!context.mounted) return;
                                  onCreated?.call();
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        subTaskController.successMessage ??
                                            'Subtask created successfully',
                                        style: GoogleFonts.inter(
                                          fontSize: 13.sp,
                                          color: Colors.white,
                                        ),
                                      ),
                                      backgroundColor: _greenOn,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } else {
                                  ss(() {
                                    isSubmitting = false;
                                    formError =
                                        subTaskController.errorMessage ??
                                        'Failed to create subtask.';
                                  });
                                }
                              },
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          child: Center(
                            child: isSubmitting
                                ? SizedBox(
                                    width: 18.w,
                                    height: 18.w,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Create Subtask',
                                    style: GoogleFonts.inter(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
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
