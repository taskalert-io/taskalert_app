import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taskalert_app/core/features/taskInstance/controllers/task_instance_controller.dart';
import 'package:taskalert_app/core/features/taskInstance/data/models/task_instance_model.dart';
import 'package:taskalert_app/utils/injection_container.dart';

import '../components/CustomAppBar.dart';
import '../components/CustomBottomNavBar.dart';
import '../components/CustomDrawer.dart';
import 'package:http/http.dart' as http;

import 'CreateOneTimeScreen.dart';
import 'CreateRepetitiveScreen.dart';
import 'MyTaskDetails.dart';

// ── API configuration ─────────────────────────────────────────────────────
class TaskApiConfig {
  static const String baseUrl = 'https://your-api.example.com';

  static const String tabCountsEndpoint = '$baseUrl/tasks/counts';
  static const String todoListEndpoint = '$baseUrl/tasks';
}

// ── Model ────────────────────────────────────────────────────────────────
class TodoItem {
  final String? id;
  final String? mainTaskId;
  final String image;
  final String title;
  final String status; // Pending | In progress | Done
  final String requestedBy;
  final String priority; // Low | High
  final String date;
  final String time;

  TodoItem({
    this.id,
    this.mainTaskId,
    this.image = '',
    this.title = '',
    this.status = '',
    this.requestedBy = '',
    this.priority = '',
    this.date = '',
    this.time = '',
  });

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id']?.toString(),
      mainTaskId: json['mainTaskId']?.toString(),
      image: json['image'] ?? '',
      title: json['title'] ?? '',
      status: json['status'] ?? '',
      requestedBy: json['requestedBy'] ?? '',
      priority: json['priority'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
    );
  }
}

// ── API service ──────────────────────────────────────────────────────────
class TaskApiService {
  final FlutterSecureStorage secureStorage;

  TaskApiService(this.secureStorage);

  Future<Map<String, String>> _headers() async {
    // final token = await secureStorage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      // 'Authorization': 'Bearer $token',
    };
  }

  /// Fetch counts for each tab.
  /// Expected response: { "today": 3, "next_day": 1, "this_week": 7, "next_week": 2 }
  Future<Map<String, int>> getTabCounts() async {
    final headers = await _headers();
    final response = await http.get(
      Uri.parse(TaskApiConfig.tabCountsEndpoint),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data.map((key, value) => MapEntry(key, (value as num).toInt()));
    }
    throw Exception('Failed to load tab counts (${response.statusCode})');
  }

  /// Fetch to-do list items for a given tab/range and sort filter.
  /// Expected response: List of items matching [TodoItem.fromJson].
  Future<List<TodoItem>> getTodoItems({
    required String range,
    required String sort,
  }) async {
    final headers = await _headers();
    final uri = Uri.parse(
      TaskApiConfig.todoListEndpoint,
    ).replace(queryParameters: {'range': range, 'sort': sort});

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((e) => TodoItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load tasks (${response.statusCode})');
  }
}

// ── Screen ───────────────────────────────────────────────────────────────
class MyTaskScreen extends StatefulWidget {
  final String userId;

  const MyTaskScreen({super.key, required this.userId});
  @override
  State<StatefulWidget> createState() => MyTaskScreenState();
}

class MyTaskScreenState extends State<MyTaskScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  Future<bool> get userTaskPermission async {
    String? permission = await secureStorage.read(key: 'user_task_permission');
    return permission == 'true';
  }

  late final TaskApiService _api = TaskApiService(secureStorage);

  static const _primaryColor = Color(0xFF0A0258);

  int _selectedTab = 0;

  // ── Tab data: label + key (for API mapping) + count ────────────────────────
  List<Map<String, dynamic>> _tabs = [
    {'label': 'Today', 'key': 'today', 'count': 0},
    {'label': 'Next Day', 'key': 'next_day', 'count': 0},
    {'label': 'This Week', 'key': 'this_week', 'count': 0},
    {'label': 'Next Week', 'key': 'next_week', 'count': 0},
  ];

  // ── Expand/collapse state per section ───────────────────────────────────────
  bool _isTodoExpanded = true;
  bool _isInProgressExpanded = false;
  bool _isCompletedExpanded = false;

  String selectedSort = "Schedule Date (ASC)";

  // ── To-do list data (per selected tab) ─────────────────────────────────────
  bool _isLoadingTodos = true;
  String? _todoError;
  List<TodoItem> _todoItems = [];

  late final TaskInstanceController taskController;

  List<Map<String, dynamic>> tasks = [];
  Map<String, dynamic> taskCounts = {};
  Map<String, dynamic> categorizedTasks = {};

  String sortBy = 'scheduledDate';
  String order = 'asc';

  String startDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String endDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _fetchTabCounts();

    taskController = sl<TaskInstanceController>();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      loadTasks('to_me', order, sortBy, startDate, endDate);
    });
  }

  Future<void> loadTasks(assigned, order, sortBy, startDate, endDate) async {
    await taskController.handleGetAllInstances(
      assigned: assigned,
      order: order,
      sortBy: sortBy,
      startDate: startDate,
      endDate: endDate,
    );

    if (!mounted) return;

    final mappedTasks = taskController.instances.map<Map<String, dynamic>>((
      TaskInstanceModel task,
    ) {
      return {
        "id": task.id,
        "instanceId": task.instanceId,
        "title": task.title,
        "description": task.description,
        "taskType": task.taskType,
        "status": task.status,
        "priority": task.priority,
        "reportingDate": task.scheduledDate,
        "reportingTime":
            "${task.scheduledTime?.time} ${task.scheduledTime?.period}",

        "createdBy": "${task.createdBy?.firstName} ${task.createdBy?.lastName}",
        // "mainTaskId": task.mainTaskId?.toString(),
        // "mainTaskId": task.mainTaskId?.toString(),
      };
    }).toList();

    final groupedTasks = <String, Map<String, dynamic>>{};

    for (final task in mappedTasks) {
      final status = task['status']?.toString() ?? 'Unknown';

      groupedTasks.putIfAbsent(
        status,
        () => {'count': 0, 'tasks': <Map<String, dynamic>>[]},
      );

      groupedTasks[status]!['tasks'].add(task);
      groupedTasks[status]!['count']++;
    }

    setState(() {
      tasks = mappedTasks;
      categorizedTasks = groupedTasks;

      taskCounts['today'] = taskController.instanceCounts?.today ?? 0;
      taskCounts['tomorrow'] = taskController.instanceCounts?.tomorrow ?? 0;
      taskCounts['thisWeek'] = taskController.instanceCounts?.thisWeek ?? 0;
      taskCounts['nextWeek'] = taskController.instanceCounts?.nextWeek ?? 0;

      _tabs = [
        {'label': 'Today', 'key': 'today', 'count': taskCounts['today']},
        {
          'label': 'Next Day',
          'key': 'next_day',
          'count': taskCounts['tomorrow'],
        },

        {
          'label': 'This Week',
          'key': 'this_week',
          'count': taskCounts['thisWeek'],
        },
        {
          'label': 'Next Week',
          'key': 'next_week',
          'count': taskCounts['nextWeek'],
        },
      ];
    });

    _fetchTodoItems();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ── Fetch tab counts from API ──────────────────────────────────────────────
  Future<void> _fetchTabCounts() async {
    try {
      // final counts = await _api.getTabCounts();
      // setState(() {
      //   for (var tab in _tabs) {
      //     tab['count'] = counts[tab['key']] ?? 0;
      //   }
      // });
    } catch (e) {
      debugPrint('Failed to fetch tab counts: $e');
    }
  }

  // ── Fetch to-do list items for the selected tab ─────────────────────────────
  // Called on init, on tab change, and when sort changes.
  Future<void> _fetchTodoItems() async {
    setState(() {
      _isLoadingTodos = true;
      _todoError = null;
    });

    try {
      final List<TodoItem> todoItems = [];

      categorizedTasks.forEach((status, data) {
        final List<Map<String, dynamic>> tasks =
            List<Map<String, dynamic>>.from(data['tasks']);

        for (final task in tasks) {
          // if (task['status'] == 'todo') {

          print('task : ${task}');

          var taskStatus = task['status'];
          if (taskStatus == 'completed') {
            taskStatus = 'Done';
          } else if (taskStatus == 'inProgress') {
            taskStatus = 'In Progress';
          } else {
            taskStatus = 'Pending';
          }

          todoItems.add(
            TodoItem(
              id: task['instanceId']?.toString() ?? '',
              mainTaskId: task['id']?.toString() ?? '',
              title: task['title'] ?? '',

              image: "",
              status: taskStatus,
              requestedBy: "Assigned by ${task['createdBy']}",
              priority:
                  task['priority'][0].toUpperCase() +
                  task['priority'].substring(1),
              date: DateFormat(
                'yyyy-MM-dd',
              ).format(DateTime.parse(task['reportingDate']?.toString() ?? '')),
              time: task['reportingTime']?.toString() ?? '',
            ),
          );
          // }
        }
      });

      _todoItems = todoItems;
    } catch (e) {
      // print(e);
      _todoError = 'Something went wrong';
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTodos = false;
        });
      }
    }
  }

  // ── Helpers: map API string values to UI colors ────────────────────────────
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'done':
        return Colors.green;
      case 'in progress':
        return Colors.orange;
      case 'pending':
      default:
        return Colors.red;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'low':
      default:
        return Colors.green;
    }
  }

  // ── Filter items by section status ──────────────────────────────────────────
  List<TodoItem> _itemsForSection(String sectionKey) {
    return _todoItems.where((item) {
      final status = item.status.toLowerCase();

      switch (sectionKey) {
        case 'in_progress':
          return status == 'in progress';
        case 'completed':
          return status == 'done';
        case 'todo':
        default:
          return status == 'pending' || status.isEmpty;
      }
    }).toList();
  }

  // ── Tab widget (gradient underline style) ───────────────────────────────────
  Widget _buildTab(String label, int count, bool isSelected) {
    return IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? _primaryColor : const Color(0xFF8B8C8E),
                ),
              ),
              SizedBox(width: 7.w),
              Container(
                width: 20.w,
                height: 20.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4E7EC),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$count',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? _primaryColor : const Color(0xFF8B8C8E),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          Container(
            width: double.infinity,
            height: 3.h,
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [
                        Color(0xFFE040FB),
                        Color(0xFF40C4FF),
                        Color(0xFF64FFDA),
                      ],
                    )
                  : null,
              color: isSelected ? null : const Color(0xFFE5E5E5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskSection({
    required String title,
    required String sectionKey,
    required bool isExpanded,
    required VoidCallback onToggleExpand,
  }) {
    final items = _itemsForSection(sectionKey);

    // print(items);

    return Container(
      margin: EdgeInsets.only(left: 15.w, right: 15.w, bottom: 15.h),
      padding: EdgeInsets.symmetric(vertical: 14.h),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// HEADER: Arrow + Title + Counter Badge
          InkWell(
            onTap: onToggleExpand,
            borderRadius: BorderRadius.circular(12.r),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ➔ Left side: Arrow, text, and circular badge count
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedRotation(
                          duration: const Duration(milliseconds: 200),
                          turns: isExpanded ? 0.5 : 0,
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            size: 20.r,
                            color: const Color(0xFF16105D),
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Flexible(
                          child: Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0D095B),
                            ),
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Container(
                          width: 20.w,
                          height: 20.w,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE4E7EC),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${items.length}',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0A0258),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                ],
              ),
            ),
          ),

          if (isExpanded) ...[
            SizedBox(height: 18.h),
            _buildTodoListBody(items, title),
          ] else
            SizedBox(height: 4.h),
        ],
      ),
    );
  }

  // ── Reusable task section card (To Do / In Progress / Completed) ────────────
  // Widget _buildTaskSection({
  //   required String title,
  //   required String sectionKey,
  //   required bool isExpanded,
  //   required VoidCallback onToggleExpand,
  // }) {
  //   final items = _itemsForSection(sectionKey);

  //   return Container(
  //     margin: EdgeInsets.only(left: 15.w, right: 15.w, bottom: 15.h),
  //     padding: const EdgeInsets.only(top: 14, bottom: 14),
  //     clipBehavior: Clip.hardEdge,
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(14.r),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(.04),
  //           blurRadius: 10,
  //           offset: const Offset(0, 4),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       children: [
  //         /// HEADER: arrow + title ............ Sort By dropdown
  //         InkWell(
  //           onTap: onToggleExpand,
  //           borderRadius: BorderRadius.circular(12.r),
  //           child: Padding(
  //             padding: EdgeInsets.symmetric(horizontal: 16.w),
  //             child: Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //               children: [
  //                 Flexible(
  //                   child: Row(
  //                     mainAxisSize: MainAxisSize.min,
  //                     children: [
  //                       GestureDetector(
  //                         onTap: onToggleExpand,
  //                         child: AnimatedRotation(
  //                           duration: const Duration(milliseconds: 200),
  //                           turns: isExpanded ? 0.5 : 0,
  //                           child: Icon(
  //                             Icons.keyboard_arrow_down,
  //                             size: 20.r,
  //                             color: const Color(0xFF16105D),
  //                           ),
  //                         ),
  //                       ),
  //                       SizedBox(width: 6.w),
  //                       Flexible(
  //                         child: Text(
  //                           title,
  //                           overflow: TextOverflow.ellipsis,
  //                           style: GoogleFonts.inter(
  //                             fontSize: 14.sp,
  //                             fontWeight: FontWeight.w700,
  //                             color: const Color(0xFF0D095B),
  //                           ),
  //                         ),
  //                       ),
  //                       SizedBox(width: 6.w),
  //                       Container(
  //                         width: 20.w,
  //                         height: 20.w,
  //                         decoration: BoxDecoration(
  //                           color: const Color(0xFFE4E7EC),
  //                           shape: BoxShape.circle,
  //                         ),
  //                         alignment: Alignment.center,
  //                         child: Text(
  //                           '${items.length}',
  //                           style: GoogleFonts.inter(
  //                             fontSize: 11.sp,
  //                             fontWeight: FontWeight.w700,
  //                             color: const Color(0xFF0A0258),
  //                           ),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),

  //                 SizedBox(width: 8.w),
  //               ],
  //             ),
  //           ),
  //         ),

  //         if (isExpanded) ...[
  //           SizedBox(height: 18.h),
  //           _buildTodoListBody(items, title),
  //         ] else
  //           SizedBox(height: 4.h),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildTodoListBody(List<TodoItem> items, String sectionTitle) {
    if (_isLoadingTodos) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 60.h),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_todoError != null) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _todoError!,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: const Color(0xFF6C7278),
                ),
              ),
              SizedBox(height: 10.h),
              TextButton(
                onPressed: _fetchTodoItems,
                child: Text(
                  "Retry",
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h),
        child: Center(
          child: Text(
            "No $sectionTitle tasks for ${_tabs[_selectedTab]['label']}",
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: const Color(0xFF6C7278),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskDetailScreen(
                      userId: widget.userId,
                      taskId: items[i].id ?? '',
                      mainTaskId: items[i].mainTaskId ?? '',
                      taskAssignedToUser: true,
                    ),
                  ),
                );
              },
              child: _buildTodoItemWrap(item: items[i]),
            ),
            if (i != items.length - 1) SizedBox(height: 12.h),
          ],
        ],
      ),
    );
  }

  // ── Wrapper: each to-do item inside its own card ────────────────────────────
  Widget _buildTodoItemWrap({required TodoItem item}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFC),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: _buildTodoItem(item: item),
    );
  }

  Widget _buildTodoItem({required TodoItem item}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// PROFILE IMAGE
        Stack(
          children: [
            CircleAvatar(
              radius: 18.r,
              backgroundColor: const Color(0xFFE4E7EC),
              backgroundImage: item.image.isNotEmpty
                  ? NetworkImage(item.image)
                  : null,
              child: item.image.isEmpty
                  ? Icon(
                      Icons.person,
                      size: 18.r,
                      color: const Color(0xFF8B8C8E),
                    )
                  : null,
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                height: 8.h,
                width: 8.w,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5.w),
                ),
              ),
            ),
          ],
        ),

        SizedBox(width: 10.w),

        /// CONTENT
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// TITLE + STATUS
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0A0258),
                      ),
                    ),
                  ),
                  if (item.status.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(item.status),
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                      child: Text(
                        item.status,
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),

              SizedBox(height: 4.h),

              /// SUBTITLE
              if (item.requestedBy.isNotEmpty)
                Text(
                  item.requestedBy,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF324054),
                  ),
                ),

              SizedBox(height: 10.h),

              /// DATE TIME PRIORITY
              Wrap(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item.date.isNotEmpty)
                        _buildInfoChip(
                          Icons.calendar_today_outlined,
                          item.date,
                        ),

                      if (item.date.isNotEmpty && item.time.isNotEmpty)
                        SizedBox(width: 12.w),

                      if (item.time.isNotEmpty)
                        _buildInfoChip(Icons.access_time, item.time),

                      if ((item.date.isNotEmpty || item.time.isNotEmpty) &&
                          item.priority.isNotEmpty)
                        SizedBox(width: 12.w),

                      if (item.priority.isNotEmpty)
                        _buildPriorityChip(item.priority),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: CustomAppBar(
        scaffoldKey: _scaffoldKey,
        userId: widget.userId,
        showLeading: true,
        onBackPressed: () => Navigator.pop(context),
      ),
      drawer: CustomDrawer(activeTile: "Home", onTileTap: (value) {}),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10.h),
            SizedBox(
              height: 40.h,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 15.w),
                child: Row(
                  children: List.generate(_tabs.length, (i) {
                    return Padding(
                      padding: EdgeInsets.only(
                        right: i < _tabs.length - 1 ? 10.w : 0,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          if (_selectedTab == i) return;
                          setState(() => _selectedTab = i);
                          // print(_tabs[i]["label"]);

                          final now = DateTime.now();
                          final formatter = DateFormat('yyyy-MM-dd');

                          DateTime startDateVal;
                          DateTime endDateVal;

                          switch (_tabs[i]["label"]) {
                            case 'Today':
                              startDateVal = now;
                              endDateVal = now;
                              break;

                            case 'Next Day':
                              startDateVal = now.add(const Duration(days: 1));
                              endDateVal = startDateVal;
                              break;

                            case 'This Week':
                              startDateVal = now;

                              // End of current week (Sunday)
                              endDateVal = now.add(
                                Duration(days: 7 - now.weekday),
                              );
                              break;

                            case 'Next Week':
                              // Start of next week (Monday)
                              startDateVal = now.add(
                                Duration(days: 8 - now.weekday),
                              );

                              // End of next week (Sunday)
                              endDateVal = startDateVal.add(
                                const Duration(days: 6),
                              );
                              break;

                            default:
                              startDateVal = now;
                              endDateVal = now;
                          }

                          // startDate = formatter.format(startDate);
                          // endDate = formatter.format(endDate);

                          startDate = DateFormat(
                            'yyyy-MM-dd',
                          ).format(startDateVal);

                          endDate = DateFormat('yyyy-MM-dd').format(endDateVal);

                          loadTasks('to_me', order, sortBy, startDate, endDate);

                          // _fetchTodoItems();
                        },
                        child: _buildTab(
                          _tabs[i]['label'] as String,
                          _tabs[i]['count'] as int,
                          _selectedTab == i,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            SizedBox(height: 14.h),

            /// 🌟 FIX: Removed the invalid outer Flexible wrapper widget here
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "Sort By : ",
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF324054),
                    ),
                  ),
                  DropdownButtonHideUnderline(
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      onSelected: (value) {
                        setState(() {
                          selectedSort = value;
                        });

                        if (selectedSort == 'Schedule Date (ASC)') {
                          sortBy = 'scheduledDate';
                          order = 'asc';
                        }
                        if (selectedSort == 'Schedule Date (DSC)') {
                          sortBy = 'scheduledDate';
                          order = 'desc';
                        }
                        if (selectedSort == 'Priority(ASC)') {
                          sortBy = 'priority';
                          order = 'asc';
                        }
                        if (selectedSort == 'Priority(DSC)') {
                          sortBy = 'priority';
                          order = 'desc';
                        }

                        loadTasks('to_me', order, sortBy, startDate, endDate);

                        // _fetchTodoItems();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: "Schedule Date (ASC)",
                          child: Text("Schedule Date (ASC)"),
                        ),
                        const PopupMenuItem(
                          value: "Schedule Date (DSC)",
                          child: Text("Schedule Date (DSC)"),
                        ),
                        const PopupMenuItem(
                          value: "Priority(ASC)",
                          child: Text("Priority(ASC)"),
                        ),
                        const PopupMenuItem(
                          value: "Priority(DSC)",
                          child: Text("Priority(DSC)"),
                        ),
                      ],
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            selectedSort,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0A0258),
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(-2, 0),
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              size: 16.r,
                              color: const Color(0xFF16105D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            /// CONTENT
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildTaskSection(
                      title: "To Do",
                      sectionKey: 'todo',
                      isExpanded: _isTodoExpanded,
                      onToggleExpand: () {
                        setState(() {
                          _isTodoExpanded = !_isTodoExpanded;
                          if (_isTodoExpanded) {
                            _isInProgressExpanded = false;
                            _isCompletedExpanded = false;
                          }
                        });
                      },
                    ),
                    _buildTaskSection(
                      title: "In Progress",
                      sectionKey: 'in_progress',
                      isExpanded: _isInProgressExpanded,
                      onToggleExpand: () {
                        setState(() {
                          _isInProgressExpanded = !_isInProgressExpanded;
                          if (_isInProgressExpanded) {
                            _isTodoExpanded = false;
                            _isCompletedExpanded = false;
                          }
                        });
                      },
                    ),
                    _buildTaskSection(
                      title: "Completed",
                      sectionKey: 'completed',
                      isExpanded: _isCompletedExpanded,
                      onToggleExpand: () {
                        setState(() {
                          _isCompletedExpanded = !_isCompletedExpanded;
                          if (_isCompletedExpanded) {
                            _isTodoExpanded = false;
                            _isInProgressExpanded = false;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: SizedBox(
        width: 56.w,
        height: 56.h,

        child: FloatingActionButton(
          backgroundColor: const Color(0xFF0A0258),
          shape: const CircleBorder(),

          onPressed: () async {
            if (await userTaskPermission) {
              showModalBottomSheet(
                context: context,
                useSafeArea: true,
                useRootNavigator: true,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,

                builder: (context) {
                  String selectedWorkspaceType = "";

                  return StatefulBuilder(
                    builder: (context, modalSetState) {
                      final bottomInset = MediaQuery.of(context).padding.bottom;

                      return Container(
                        padding: EdgeInsets.only(
                          left: 20.w,
                          right: 20.w,
                          top: 18.h,
                          bottom: bottomInset > 0 ? bottomInset : 25.h,
                        ),

                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(28.r),
                            topRight: Radius.circular(28.r),
                          ),
                        ),

                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            /// HEADER
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),

                                  child: Icon(
                                    Icons.close,
                                    size: 16.r,
                                    color: const Color(0xFF101828),
                                  ),
                                ),

                                Expanded(
                                  child: Center(
                                    child: Text(
                                      "Create New Workspace",

                                      style: GoogleFonts.inter(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF0A0258),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 15.h),

                            Divider(color: const Color(0xFFE4E7EC), height: 1),

                            SizedBox(height: 15.h),

                            /// SELECT TEXT
                            Align(
                              alignment: Alignment.centerLeft,

                              child: Text(
                                "Select one",

                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF324054),
                                ),
                              ),
                            ),

                            SizedBox(height: 10.h),

                            /// =========================
                            /// REPETITIVE
                            /// =========================
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      modalSetState(() {
                                        if (selectedWorkspaceType ==
                                            "Repetitive") {
                                          selectedWorkspaceType = "";
                                        } else {
                                          selectedWorkspaceType = "Repetitive";
                                        }
                                      });
                                    },

                                    child: Row(
                                      children: [
                                        /// RADIO
                                        Container(
                                          width: 16.w,
                                          height: 16.w,

                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: const Color(0xFF0A0258),
                                              width: 1.3,
                                            ),
                                          ),

                                          child: Center(
                                            child: Container(
                                              width: 10.w,
                                              height: 10.w,

                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color:
                                                    selectedWorkspaceType ==
                                                        "Repetitive"
                                                    ? const Color(0xFF24116A)
                                                    : Colors.transparent,
                                              ),
                                            ),
                                          ),
                                        ),

                                        SizedBox(width: 10.w),

                                        /// TITLE
                                        Text(
                                          "Repetitive",

                                          style: GoogleFonts.inter(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF3F3F3F),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                /// ARROW BUTTON
                                GestureDetector(
                                  onTap: selectedWorkspaceType == "Repetitive"
                                      ? () {
                                          Navigator.pop(context);

                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  CreateRepetitiveScreen(
                                                    userId: '',
                                                  ),
                                            ),
                                          );
                                        }
                                      : null,

                                  child: Container(
                                    width: 27.w,
                                    height: 27.w,

                                    decoration: BoxDecoration(
                                      color:
                                          selectedWorkspaceType == "Repetitive"
                                          ? const Color(0xFFE4E7EC)
                                          : const Color(0xFFF2F4F7),

                                      borderRadius: BorderRadius.circular(5.r),
                                    ),

                                    child: Icon(
                                      Icons.arrow_forward,
                                      size: 15.r,

                                      color:
                                          selectedWorkspaceType == "Repetitive"
                                          ? const Color(0xFF667085)
                                          : const Color(0xFF98A2B3),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 10.h),

                            /// =========================
                            /// ONE TIME
                            /// =========================
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      modalSetState(() {
                                        if (selectedWorkspaceType ==
                                            "One-time") {
                                          selectedWorkspaceType = "";
                                        } else {
                                          selectedWorkspaceType = "One-time";
                                        }
                                      });
                                    },

                                    child: Row(
                                      children: [
                                        /// RADIO
                                        Container(
                                          width: 16.w,
                                          height: 16.w,

                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: const Color(0xFF0A0258),
                                              width: 1.3,
                                            ),
                                          ),

                                          child: Center(
                                            child: Container(
                                              width: 10.w,
                                              height: 10.w,

                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color:
                                                    selectedWorkspaceType ==
                                                        "One-time"
                                                    ? const Color(0xFF24116A)
                                                    : Colors.transparent,
                                              ),
                                            ),
                                          ),
                                        ),

                                        SizedBox(width: 10.w),

                                        /// TITLE
                                        Text(
                                          "One-time",

                                          style: GoogleFonts.inter(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF3F3F3F),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                /// ARROW BUTTON
                                GestureDetector(
                                  onTap: selectedWorkspaceType == "One-time"
                                      ? () {
                                          Navigator.pop(context);

                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  CreateOneTimeScreen(
                                                    userId: '',
                                                  ),
                                            ),
                                          );
                                        }
                                      : null,

                                  child: Container(
                                    width: 27.w,
                                    height: 27.w,

                                    decoration: BoxDecoration(
                                      color: selectedWorkspaceType == "One-time"
                                          ? const Color(0xFFE4E7EC)
                                          : const Color(0xFFF2F4F7),

                                      borderRadius: BorderRadius.circular(5.r),
                                    ),

                                    child: Icon(
                                      Icons.arrow_forward,
                                      size: 15.r,

                                      color: selectedWorkspaceType == "One-time"
                                          ? const Color(0xFF667085)
                                          : const Color(0xFF98A2B3),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 15.h),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('You are not authorized to create tasks.'),
                  duration: Duration(seconds: 3),
                ),
              );
            }
          },

          child: Icon(Icons.add, color: Colors.white, size: 34.r),
        ),
      ),

      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 1),
    );
  }
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     key: _scaffoldKey,
  //     backgroundColor: const Color(0xFFF5F7FB),
  //     appBar: CustomAppBar(
  //       scaffoldKey: _scaffoldKey,
  //       userId: widget.userId,
  //       showLeading: true,
  //       onBackPressed: () => Navigator.pop(context),
  //     ),
  //     drawer: CustomDrawer(activeTile: "Home", onTileTap: (value) {}),
  //     body: GestureDetector(
  //       behavior: HitTestBehavior.opaque,
  //       onTap: () => FocusScope.of(context).unfocus(),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           SizedBox(height: 10.h),
  //           SizedBox(
  //             height: 40.h,
  //             child: SingleChildScrollView(
  //               scrollDirection: Axis.horizontal,
  //               padding: EdgeInsets.symmetric(horizontal: 15.w),
  //               child: Row(
  //                 children: List.generate(_tabs.length, (i) {
  //                   return Padding(
  //                     padding: EdgeInsets.only(
  //                       right: i < _tabs.length - 1 ? 10.w : 0,
  //                     ),
  //                     child: GestureDetector(
  //                       onTap: () {
  //                         if (_selectedTab == i) return;
  //                         setState(() => _selectedTab = i);
  //                         _fetchTodoItems();
  //                       },
  //                       child: _buildTab(
  //                         _tabs[i]['label'] as String,
  //                         _tabs[i]['count'] as int,
  //                         _selectedTab == i,
  //                       ),
  //                     ),
  //                   );
  //                 }),
  //               ),
  //             ),
  //           ),
  //           SizedBox(height: 14.h),
  //           Padding(
  //             padding: EdgeInsets.symmetric(horizontal: 15.w),
  //             child: Flexible(
  //               child: Row(
  //                 mainAxisAlignment: MainAxisAlignment.end,
  //                 children: [
  //                   Text(
  //                     "Sort By :",
  //                     style: GoogleFonts.inter(
  //                       fontSize: 11.sp,
  //                       fontWeight: FontWeight.w500,
  //                       color: const Color(0xFF324054),
  //                     ),
  //                   ),
  //                   SizedBox(height: 2.h),
  //                   DropdownButtonHideUnderline(
  //                     child: PopupMenuButton<String>(
  //                       padding: EdgeInsets.zero,
  //                       onSelected: (value) {
  //                         setState(() {
  //                           selectedSort = value;
  //                         });
  //                         _fetchTodoItems();
  //                       },
  //                       itemBuilder: (context) => [
  //                         const PopupMenuItem(
  //                           value: "Schedule Date (ASC)",
  //                           child: Text("Schedule Date (ASC)"),
  //                         ),
  //                         const PopupMenuItem(
  //                           value: "Schedule Date (DSC)",
  //                           child: Text("Schedule Date (DSC)"),
  //                         ),
  //                         const PopupMenuItem(
  //                           value: "Priority(ASC)",
  //                           child: Text("Priority(ASC)"),
  //                         ),
  //                         const PopupMenuItem(
  //                           value: "Priority(DSC)",
  //                           child: Text("Priority(DSC)"),
  //                         ),
  //                       ],
  //                       child: Row(
  //                         mainAxisSize: MainAxisSize.min,
  //                         children: [
  //                           Flexible(
  //                             child: Text(
  //                               selectedSort,
  //                               overflow: TextOverflow.ellipsis,
  //                               maxLines: 1,
  //                               style: GoogleFonts.inter(
  //                                 fontSize: 12.sp,
  //                                 fontWeight: FontWeight.w700,
  //                                 color: const Color(0xFF0A0258),
  //                               ),
  //                             ),
  //                           ),
  //                           Transform.translate(
  //                             offset: const Offset(-2, 0),
  //                             child: Icon(
  //                               Icons.keyboard_arrow_down,
  //                               size: 16.r,
  //                               color: const Color(0xFF16105D),
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //           SizedBox(height: 14.h),

  //           /// CONTENT
  //           Expanded(
  //             child: SingleChildScrollView(
  //               physics: const AlwaysScrollableScrollPhysics(),
  //               child: Column(
  //                 children: [
  //                   _buildTaskSection(
  //                     title: "To Do",
  //                     sectionKey: 'todo',
  //                     isExpanded: _isTodoExpanded,
  //                     onToggleExpand: () {
  //                       setState(() {
  //                         _isTodoExpanded = !_isTodoExpanded;

  //                         if (_isTodoExpanded) {
  //                           _isInProgressExpanded = false;
  //                           _isCompletedExpanded = false;
  //                         }
  //                       });
  //                     },
  //                   ),
  //                   _buildTaskSection(
  //                     title: "In Progress",
  //                     sectionKey: 'in_progress',
  //                     isExpanded: _isInProgressExpanded,
  //                     onToggleExpand: () {
  //                       setState(() {
  //                         _isInProgressExpanded = !_isInProgressExpanded;

  //                         if (_isInProgressExpanded) {
  //                           _isTodoExpanded = false;
  //                           _isCompletedExpanded = false;
  //                         }
  //                       });
  //                     },
  //                   ),
  //                   _buildTaskSection(
  //                     title: "Completed",
  //                     sectionKey: 'completed',
  //                     isExpanded: _isCompletedExpanded,
  //                     onToggleExpand: () {
  //                       setState(() {
  //                         _isCompletedExpanded = !_isCompletedExpanded;

  //                         if (_isCompletedExpanded) {
  //                           _isTodoExpanded = false;
  //                           _isInProgressExpanded = false;
  //                         }
  //                       });
  //                     },
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //     floatingActionButton: SizedBox(
  //       width: 56.w,
  //       height: 56.h,
  //       child: FloatingActionButton(
  //         backgroundColor: const Color(0xFF0A0258),
  //         shape: const CircleBorder(),
  //         onPressed: () {
  //           showModalBottomSheet(
  //             context: context,
  //             useSafeArea: true,
  //             useRootNavigator: true,
  //             backgroundColor: Colors.transparent,
  //             isScrollControlled: true,
  //             builder: (context) {
  //               String selectedWorkspaceType = "";

  //               return StatefulBuilder(
  //                 builder: (context, modalSetState) {
  //                   final bottomInset = MediaQuery.of(context).padding.bottom;

  //                   return Container(
  //                     padding: EdgeInsets.only(
  //                       left: 20.w,
  //                       right: 20.w,
  //                       top: 18.h,
  //                       bottom: bottomInset > 0 ? bottomInset : 25.h,
  //                     ),
  //                     decoration: BoxDecoration(
  //                       color: Colors.white,
  //                       borderRadius: BorderRadius.only(
  //                         topLeft: Radius.circular(28.r),
  //                         topRight: Radius.circular(28.r),
  //                       ),
  //                     ),
  //                     child: Column(
  //                       mainAxisSize: MainAxisSize.min,
  //                       children: [
  //                         /// HEADER
  //                         Row(
  //                           children: [
  //                             GestureDetector(
  //                               onTap: () => Navigator.pop(context),
  //                               child: Icon(
  //                                 Icons.close,
  //                                 size: 16.r,
  //                                 color: const Color(0xFF101828),
  //                               ),
  //                             ),
  //                             Expanded(
  //                               child: Center(
  //                                 child: Text(
  //                                   "Create New Workspace",
  //                                   style: GoogleFonts.inter(
  //                                     fontSize: 14.sp,
  //                                     fontWeight: FontWeight.w600,
  //                                     color: const Color(0xFF0A0258),
  //                                   ),
  //                                 ),
  //                               ),
  //                             ),
  //                           ],
  //                         ),

  //                         SizedBox(height: 15.h),

  //                         Divider(color: const Color(0xFFE4E7EC), height: 1),

  //                         SizedBox(height: 15.h),

  //                         /// SELECT TEXT
  //                         Align(
  //                           alignment: Alignment.centerLeft,
  //                           child: Text(
  //                             "Select one",
  //                             style: GoogleFonts.inter(
  //                               fontSize: 12.sp,
  //                               fontWeight: FontWeight.w500,
  //                               color: const Color(0xFF324054),
  //                             ),
  //                           ),
  //                         ),

  //                         SizedBox(height: 10.h),

  //                         /// =========================
  //                         /// REPETITIVE
  //                         /// =========================
  //                         Row(
  //                           children: [
  //                             Expanded(
  //                               child: GestureDetector(
  //                                 onTap: () {
  //                                   modalSetState(() {
  //                                     if (selectedWorkspaceType ==
  //                                         "Repetitive") {
  //                                       selectedWorkspaceType = "";
  //                                     } else {
  //                                       selectedWorkspaceType = "Repetitive";
  //                                     }
  //                                   });
  //                                 },
  //                                 child: Row(
  //                                   children: [
  //                                     /// RADIO
  //                                     Container(
  //                                       width: 16.w,
  //                                       height: 16.w,
  //                                       decoration: BoxDecoration(
  //                                         shape: BoxShape.circle,
  //                                         border: Border.all(
  //                                           color: const Color(0xFF0A0258),
  //                                           width: 1.3,
  //                                         ),
  //                                       ),
  //                                       child: Center(
  //                                         child: Container(
  //                                           width: 10.w,
  //                                           height: 10.w,
  //                                           decoration: BoxDecoration(
  //                                             shape: BoxShape.circle,
  //                                             color:
  //                                                 selectedWorkspaceType ==
  //                                                     "Repetitive"
  //                                                 ? const Color(0xFF24116A)
  //                                                 : Colors.transparent,
  //                                           ),
  //                                         ),
  //                                       ),
  //                                     ),
  //                                     SizedBox(width: 10.w),

  //                                     /// TITLE
  //                                     Text(
  //                                       "Repetitive",
  //                                       style: GoogleFonts.inter(
  //                                         fontSize: 14.sp,
  //                                         fontWeight: FontWeight.w500,
  //                                         color: const Color(0xFF3F3F3F),
  //                                       ),
  //                                     ),
  //                                   ],
  //                                 ),
  //                               ),
  //                             ),

  //                             /// ARROW BUTTON
  //                             GestureDetector(
  //                               onTap: selectedWorkspaceType == "Repetitive"
  //                                   ? () {
  //                                       Navigator.pop(context);
  //                                       Navigator.push(
  //                                         context,
  //                                         MaterialPageRoute(
  //                                           builder: (context) =>
  //                                               CreateRepetitiveScreen(
  //                                                 userId: '',
  //                                               ),
  //                                         ),
  //                                       );
  //                                     }
  //                                   : null,
  //                               child: Container(
  //                                 width: 27.w,
  //                                 height: 27.w,
  //                                 decoration: BoxDecoration(
  //                                   color: selectedWorkspaceType == "Repetitive"
  //                                       ? const Color(0xFFE4E7EC)
  //                                       : const Color(0xFFF2F4F7),
  //                                   borderRadius: BorderRadius.circular(5.r),
  //                                 ),
  //                                 child: Icon(
  //                                   Icons.arrow_forward,
  //                                   size: 15.r,
  //                                   color: selectedWorkspaceType == "Repetitive"
  //                                       ? const Color(0xFF667085)
  //                                       : const Color(0xFF98A2B3),
  //                                 ),
  //                               ),
  //                             ),
  //                           ],
  //                         ),

  //                         SizedBox(height: 10.h),

  //                         /// =========================
  //                         /// ONE TIME
  //                         /// =========================
  //                         Row(
  //                           children: [
  //                             Expanded(
  //                               child: GestureDetector(
  //                                 onTap: () {
  //                                   modalSetState(() {
  //                                     if (selectedWorkspaceType == "One-time") {
  //                                       selectedWorkspaceType = "";
  //                                     } else {
  //                                       selectedWorkspaceType = "One-time";
  //                                     }
  //                                   });
  //                                 },
  //                                 child: Row(
  //                                   children: [
  //                                     /// RADIO
  //                                     Container(
  //                                       width: 16.w,
  //                                       height: 16.w,
  //                                       decoration: BoxDecoration(
  //                                         shape: BoxShape.circle,
  //                                         border: Border.all(
  //                                           color: const Color(0xFF0A0258),
  //                                           width: 1.3,
  //                                         ),
  //                                       ),
  //                                       child: Center(
  //                                         child: Container(
  //                                           width: 10.w,
  //                                           height: 10.w,
  //                                           decoration: BoxDecoration(
  //                                             shape: BoxShape.circle,
  //                                             color:
  //                                                 selectedWorkspaceType ==
  //                                                     "One-time"
  //                                                 ? const Color(0xFF24116A)
  //                                                 : Colors.transparent,
  //                                           ),
  //                                         ),
  //                                       ),
  //                                     ),
  //                                     SizedBox(width: 10.w),

  //                                     /// TITLE
  //                                     Text(
  //                                       "One-time",
  //                                       style: GoogleFonts.inter(
  //                                         fontSize: 14.sp,
  //                                         fontWeight: FontWeight.w500,
  //                                         color: const Color(0xFF3F3F3F),
  //                                       ),
  //                                     ),
  //                                   ],
  //                                 ),
  //                               ),
  //                             ),

  //                             /// ARROW BUTTON
  //                             GestureDetector(
  //                               onTap: selectedWorkspaceType == "One-time"
  //                                   ? () {
  //                                       Navigator.pop(context);
  //                                       Navigator.push(
  //                                         context,
  //                                         MaterialPageRoute(
  //                                           builder: (context) =>
  //                                               CreateOneTimeScreen(userId: ''),
  //                                         ),
  //                                       );
  //                                     }
  //                                   : null,
  //                               child: Container(
  //                                 width: 27.w,
  //                                 height: 27.w,
  //                                 decoration: BoxDecoration(
  //                                   color: selectedWorkspaceType == "One-time"
  //                                       ? const Color(0xFFE4E7EC)
  //                                       : const Color(0xFFF2F4F7),
  //                                   borderRadius: BorderRadius.circular(5.r),
  //                                 ),
  //                                 child: Icon(
  //                                   Icons.arrow_forward,
  //                                   size: 15.r,
  //                                   color: selectedWorkspaceType == "One-time"
  //                                       ? const Color(0xFF667085)
  //                                       : const Color(0xFF98A2B3),
  //                                 ),
  //                               ),
  //                             ),
  //                           ],
  //                         ),
  //                         SizedBox(height: 15.h),
  //                       ],
  //                     ),
  //                   );
  //                 },
  //               );
  //             },
  //           );
  //         },
  //         child: Icon(Icons.add, color: Colors.white, size: 34.r),
  //       ),
  //     ),
  //     bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 1),
  //   );
  // }

  Widget _buildInfoChip(IconData icon, String text) {
    return IntrinsicWidth(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.r, color: const Color(0xFF324054)),
          SizedBox(width: 4.w),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: const Color(0xFF324054),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityChip(String priority) {
    return IntrinsicWidth(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7.w,
            height: 7.h,
            decoration: BoxDecoration(
              color: _priorityColor(priority),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 5.w),
          Text(
            priority,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: const Color(0xFF324054),
            ),
          ),
        ],
      ),
    );
  }
}
