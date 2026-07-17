import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/features/employees/controllers/employee_controller.dart';
import '../core/features/subTasks/data/models/sub_task_instance_model.dart'
    show SubTaskTime;
import '../core/features/taskInstance/controllers/task_instance_controller.dart';
import 'SubtaskDialogs.dart'
    show
        subtaskStatusColor,
        subtaskStatusLabel,
        subtaskStatusOptions,
        parseSubtaskTime,
        pickSubtaskAssignees,
        employeeNameById;

const _primaryColor = Color(0xFF0A0258);
const _accentColor = Color(0xFF4A4A4A);
const _labelColor = Color(0xFF797979);
const _greenOn = Color(0xFF1DC230);

const _priorityOptions = ['low', 'medium', 'high'];

String _priorityLabel(String priority) => switch (priority.toLowerCase()) {
  'high' => 'High',
  'medium' => 'Medium',
  _ => 'Low',
};

/// Reusable "Edit Task" bottom sheet for a main task instance (as opposed
/// to a subtask) — a lighter-weight alternative to `MyTaskDetails.dart`'s
/// own whole-screen inline "unlock to edit" mode (title/description/
/// schedule/status all editable there), covering just priority, assignees
/// and scheduled time via the partial-update endpoint. [onUpdated] fires
/// after a successful update, for the caller to refresh its own view.
void openEditTaskInstanceDialog({
  required BuildContext context,
  required String taskId,
  required String instanceId,
  required String currentStatus,
  String? initialPriority,
  required List<String> initialAssigneeIds,
  SubTaskTime? initialScheduledTime,
  required TaskInstanceController taskInstanceController,
  required EmployeeController employeeController,
  VoidCallback? onUpdated,
}) {
  List<String> selectedAssigneeIds = List.from(initialAssigneeIds);
  String selectedPriority = (initialPriority ?? 'low').toLowerCase();
  TimeOfDay? selectedTime = parseSubtaskTime(initialScheduledTime);
  String updateScope = 'single';
  bool isSubmitting = false;
  String? formError;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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
                      'Edit Task',
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
                  'Priority',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: _labelColor,
                  ),
                ),
                SizedBox(height: 6.h),
                Wrap(
                  spacing: 8.w,
                  children: [
                    for (final option in _priorityOptions)
                      ChoiceChip(
                        label: Text(_priorityLabel(option)),
                        selected: selectedPriority == option,
                        onSelected: (_) => ss(() => selectedPriority = option),
                        selectedColor: _primaryColor.withOpacity(0.12),
                        labelStyle: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: selectedPriority == option
                              ? _primaryColor
                              : _accentColor,
                          fontWeight: selectedPriority == option
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                  ],
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
                    final result = await pickSubtaskAssignees(
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
                          ? 'Select assignees'
                          : selectedAssigneeIds
                                .map(
                                  (id) =>
                                      employeeNameById(
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
                  'Scheduled Time',
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
                    'Only this task',
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
                    'This and all future tasks',
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
                                ss(() {
                                  formError = null;
                                  isSubmitting = true;
                                });

                                String? time;
                                String? period;
                                if (selectedTime != null) {
                                  final hour12 = selectedTime!.hourOfPeriod == 0
                                      ? 12
                                      : selectedTime!.hourOfPeriod;
                                  time =
                                      '${hour12.toString().padLeft(2, '0')}:'
                                      '${selectedTime!.minute.toString().padLeft(2, '0')}';
                                  period = selectedTime!.period == DayPeriod.am
                                      ? 'AM'
                                      : 'PM';
                                }

                                final success = await taskInstanceController
                                    .handleUpdateInstanceConfiguration(
                                      taskId: taskId,
                                      instanceId: instanceId,
                                      status: currentStatus,
                                      priority: selectedPriority,
                                      assigneeIds: selectedAssigneeIds,
                                      time: time,
                                      period: period,
                                      scope: updateScope,
                                    );

                                if (!ctx.mounted) return;

                                if (success) {
                                  Navigator.pop(ctx);
                                  if (!context.mounted) return;
                                  onUpdated?.call();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        taskInstanceController.successMessage ??
                                            'Task updated successfully',
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
                                        taskInstanceController.errorMessage ??
                                        'Failed to update task.';
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
                                    'Save Changes',
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

/// Reusable "Update Status" bottom sheet for a main task instance — same
/// Todo/In Progress/Completed vocabulary as subtasks (see
/// `SubtaskDialogs.dart`), submitted via the lightweight partial-update
/// endpoint rather than the full configuration one. [onUpdated] fires
/// after a successful update, for the caller to refresh its own view.
Future<void> showUpdateTaskInstanceStatusSheet({
  required BuildContext context,
  required String taskId,
  required String instanceId,
  required String currentStatus,
  required TaskInstanceController taskInstanceController,
  VoidCallback? onUpdated,
}) async {
  final normalizedCurrent = currentStatus.toLowerCase();

  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (sheetCtx) => Container(
      padding: EdgeInsets.symmetric(vertical: 8.h),
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
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 4.h),
              child: Text(
                'Update Status',
                style: GoogleFonts.inter(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: _primaryColor,
                ),
              ),
            ),
            for (final option in subtaskStatusOptions)
              ListTile(
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  if (option.toLowerCase() == normalizedCurrent) return;

                  final success = await taskInstanceController
                      .handleUpdateInstanceStatusPriorityAssignees(
                        taskId: taskId,
                        instanceId: instanceId,
                        status: option,
                      );

                  if (!context.mounted) return;
                  onUpdated?.call();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? (taskInstanceController.successMessage ??
                                  'Status updated')
                            : (taskInstanceController.errorMessage ??
                                  'Could not update status'),
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: success ? _greenOn : Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                leading: Icon(
                  Icons.circle,
                  size: 12.r,
                  color: subtaskStatusColor(option),
                ),
                title: Text(
                  subtaskStatusLabel(option),
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: _accentColor,
                  ),
                ),
                trailing: option.toLowerCase() == normalizedCurrent
                    ? Icon(Icons.check, size: 18.r, color: _primaryColor)
                    : null,
              ),
          ],
        ),
      ),
    ),
  );
}
