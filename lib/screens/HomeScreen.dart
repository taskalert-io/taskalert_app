import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:taskalert_app/core/features/taskInstance/controllers/task_instance_controller.dart';
import 'package:taskalert_app/core/features/taskInstance/data/models/task_instance_model.dart';
import 'package:taskalert_app/screens/CreateOneTimeScreen.dart';
import 'package:taskalert_app/utils/injection_container.dart';
import '../components/CustomAppBar.dart';
import '../components/CustomBottomNavBar.dart';
import '../components/CustomDrawer.dart';

import 'MyTaskDetails.dart';
import 'CreateRepetitiveScreen.dart';
import 'organization_setup_dialog.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  const HomeScreen({super.key, required this.userId});

  @override
  State<StatefulWidget> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  late final TaskInstanceController taskController;
  late final TaskInstanceController overdueTaskController;
  String startDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String endDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  List<Map<String, dynamic>> tasks = [];
  bool _isLoadingTasks = true;
  List<Map<String, dynamic>> overdueTasks = [];
  bool _isLoadingOverdueTasks = true;

  @override
  void initState() {
    super.initState();
    // ✅ After HomeScreen is fully built and visible on screen,
    // check if we need to show the OrganizationSetupDialog.
    taskController = sl<TaskInstanceController>();
    overdueTaskController = sl<TaskInstanceController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowOrgDialog();
      _loadTodoTasks();
      _loadOverdueTasks();
    });
  }

  List<Map<String, dynamic>> _mapInstancesToTasks(
    List<TaskInstanceModel> instances,
  ) {
    return instances.map<Map<String, dynamic>>((task) {
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

        "createdBy":
            "${task.createdBy?.firstName} ${task.createdBy?.lastName}",
      };
    }).toList();
  }

  Future<void> _loadTodoTasks() async {
    await taskController.handleGetAllInstances(
      assigned: 'to_me',
      status: 'todo',
      startDate: startDate,
      endDate: endDate,
    );

    setState(() {
      tasks = _mapInstancesToTasks(taskController.instances);
      _isLoadingTasks = false;
    });
  }

  Future<void> _loadOverdueTasks() async {
    // No date range here — overdue tasks are, by definition, ones whose
    // scheduled date has already passed, so scoping to "today" would
    // exclude them.
    await overdueTaskController.handleGetAllInstances(
      assigned: 'to_me',
      overdue: true,
    );

    setState(() {
      overdueTasks = _mapInstancesToTasks(overdueTaskController.instances);
      _isLoadingOverdueTasks = false;
    });
  }

  Future<bool> get userTaskPermission async {
    String? permission = await secureStorage.read(key: 'user_task_permission');
    return permission == 'true';
  }

  Future<void> _checkAndShowOrgDialog() async {
    final pendingAccountType = await secureStorage.read(
      key: 'user_requires_organization',
    );

    final shouldShow = (pendingAccountType == 'true');

    if (shouldShow && mounted) {
      // ✅ Clean up pending flag before showing dialog
      // await secureStorage.delete(key: 'pending_account_type');

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const OrganizationSetupDialog(),
      );
    }
  }

  /// PAGE CONTROLLER
  final PageController _pageController = PageController(
    viewportFraction: .62,
    initialPage: 1000,
  );

  final PageController _todoController = PageController();
  final PageController _overdueController = PageController();

  /// Upcoming/recent to-do tasks shown in the Work List slider (max 3).
  List<Map<String, dynamic>> get _recentTasks => tasks.take(3).toList();

  final ValueNotifier<int> currentPageNotifier = ValueNotifier<int>(1000);
  final ValueNotifier<int> todoCurrentPageNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> overdueCurrentPageNotifier = ValueNotifier<int>(0);
  String selectedSort = "All";
  String selectedWorkspaceType = "";

  @override
  void dispose() {
    _pageController.dispose();
    _todoController.dispose();
    _overdueController.dispose();
    currentPageNotifier.dispose();
    todoCurrentPageNotifier.dispose();
    overdueCurrentPageNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(
        scaffoldKey: _scaffoldKey,
        userId: widget.userId,
        showLeading: true,
        onBackPressed: () {
          Navigator.pop(context);
        },
      ),
      drawer: CustomDrawer(activeTile: "Home", onTileTap: (value) {}),

      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            color: const Color(0xFFF5F7FB),
            width: double.infinity,
            child: Column(
              children: [
                /// TOP SLIDER SECTION
                Container(
                  margin: const EdgeInsets.only(
                    top: 10,
                    left: 15,
                    right: 15,
                    bottom: 15,
                  ),
                  height: 215.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24.r),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFE8D9FF), Color(0xFFF3ECFF)],
                    ),
                  ),
                  child: Column(
                    children: [
                      /// HEADER
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 14,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Work List",
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0A0258),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 14.h),

                      /// PAGEVIEW — upcoming/recent tasks, or empty state
                      if (_isLoadingTasks)
                        SizedBox(
                          height: 135.h,
                          child: Center(
                            child: SizedBox(
                              width: 24.w,
                              height: 24.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Color(0xFF4338CA),
                              ),
                            ),
                          ),
                        )
                      else if (_recentTasks.isEmpty)
                        SizedBox(
                          height: 135.h,
                          child: Center(
                            child: Text(
                              "No recent works",
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF7B7B95),
                              ),
                            ),
                          ),
                        )
                      else ...[
                        SizedBox(
                          height: 135.h,
                          child: ValueListenableBuilder<int>(
                            valueListenable: currentPageNotifier,
                            builder: (context, currentPage, child) {
                              return PageView.builder(
                                controller: _pageController,
                                itemCount: null,
                                onPageChanged: (index) {
                                  currentPageNotifier.value = index;
                                },
                                itemBuilder: (context, index) {
                                  final realIndex =
                                      index % _recentTasks.length;
                                  final item = _recentTasks[realIndex];
                                  final isActive =
                                      currentPage % _recentTasks.length ==
                                      realIndex;
                                  return GestureDetector(
                                    onTap: () {
                                      if (isActive) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                TaskDetailScreen(
                                                  userId: widget.userId,
                                                  mainTaskId: item["id"],
                                                  taskId: item["instanceId"],
                                                ),
                                          ),
                                        );
                                        return;
                                      }
                                      _pageController.animateToPage(
                                        index,
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeInOut,
                                      );
                                      currentPageNotifier.value = index;
                                    },
                                    child: Center(
                                      child: _buildCard(
                                        number: (realIndex + 1)
                                            .toString()
                                            .padLeft(2, '0'),
                                        title: item["title"]?.toString() ?? '',
                                        scheduledDate:
                                            item["reportingDate"]
                                                is DateTime
                                            ? DateFormat('MMM d').format(
                                                item["reportingDate"]
                                                    as DateTime,
                                              )
                                            : '',
                                        scheduledTime:
                                            item["reportingTime"]
                                                ?.toString() ??
                                            '',
                                        priority:
                                            item["priority"]?.toString() ??
                                            '',
                                        isActive: isActive,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),

                        SizedBox(height: 15.h),

                        /// DOT INDICATOR
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ValueListenableBuilder<int>(
                            valueListenable: currentPageNotifier,
                            builder: (context, currentPage, child) {
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  _recentTasks.length,
                                  (index) => GestureDetector(
                                    onTap: () {
                                      final targetPage =
                                          currentPage -
                                          (currentPage %
                                              _recentTasks.length) +
                                          index;
                                      _pageController.animateToPage(
                                        targetPage,
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeInOut,
                                      );
                                      currentPageNotifier.value = targetPage;
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 3,
                                      ),
                                      child: _dot(
                                        currentPage % _recentTasks.length ==
                                            index,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                Container(
                  margin: EdgeInsets.only(left: 15, right: 15, bottom: 15),
                  padding: const EdgeInsets.only(
                    left: 10,
                    right: 10,
                    top: 18,
                    bottom: 14,
                  ),
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      /// TOP HEADER
                      Padding(
                        padding: EdgeInsets.only(left: 16, right: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "To-do List",
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0D095B),
                              ),
                            ),

                            // Row(
                            //   children: [
                            //     Text(
                            //       "Sort By : ",
                            //       style: GoogleFonts.inter(
                            //         fontSize: 12.sp,
                            //         fontWeight: FontWeight.w500,
                            //         color: const Color(0xFF324054),
                            //       ),
                            //     ),
                            //     DropdownButtonHideUnderline(
                            //       child: PopupMenuButton<String>(
                            //         padding: EdgeInsets.zero,
                            //         onSelected: (value) {
                            //           setState(() {
                            //             selectedSort = value;
                            //           });
                            //         },
                            //         itemBuilder: (context) => [
                            //           const PopupMenuItem(
                            //             value: "All",
                            //             child: Text("All"),
                            //           ),
                            //           const PopupMenuItem(
                            //             value: "Pending",
                            //             child: Text("Pending"),
                            //           ),
                            //           const PopupMenuItem(
                            //             value: "Done",
                            //             child: Text("Done"),
                            //           ),
                            //           const PopupMenuItem(
                            //             value: "High",
                            //             child: Text("High"),
                            //           ),
                            //         ],
                            //         child: Row(
                            //           mainAxisSize: MainAxisSize.min,
                            //           children: [
                            //             Text(
                            //               selectedSort,
                            //               style: GoogleFonts.inter(
                            //                 fontSize: 12.sp,
                            //                 fontWeight: FontWeight.w700,
                            //                 color: const Color(0xFF0A0258),
                            //               ),
                            //             ),
                            //             Transform.translate(
                            //               offset: const Offset(-2, 0),
                            //               child: Icon(
                            //                 Icons.keyboard_arrow_down,
                            //                 size: 16.r,
                            //                 color: const Color(0xFF16105D),
                            //               ),
                            //             ),
                            //           ],
                            //         ),
                            //       ),
                            //     ),
                            //   ],
                            // ),
                          ],
                        ),
                      ),

                      SizedBox(height: 18.h),

                      /// SLIDER
                      SizedBox(
                        height: 300.h,
                        child: PageView(
                          controller: _todoController,
                          onPageChanged: (index) {
                            todoCurrentPageNotifier.value = index;
                          },
                          children: [
                            /// PAGE 1
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    if (_isLoadingTasks)
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 60.h,
                                        ),
                                        child: Center(
                                          child: SizedBox(
                                            width: 28.w,
                                            height: 28.w,
                                            child: const CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Color(0xFF4338CA),
                                            ),
                                          ),
                                        ),
                                      )
                                    else if (tasks.isEmpty)
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 60.h,
                                        ),
                                        child: Center(
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.check_circle_outline,
                                                size: 40.r,
                                                color: const Color(0xFFB8BEC5),
                                              ),
                                              SizedBox(height: 8.h),
                                              Text(
                                                "No tasks assigned",
                                                style: GoogleFonts.inter(
                                                  fontSize: 13.sp,
                                                  fontWeight: FontWeight.w500,
                                                  color: const Color(
                                                    0xFF9AA0AB,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    else
                                      for (final task in tasks) ...[
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  TaskDetailScreen(
                                                    userId: widget.userId,
                                                    mainTaskId: task["id"],
                                                    taskId: task["instanceId"],
                                                  ),
                                            ),
                                          );
                                        },
                                        child: _buildTodoItem(
                                          image: "",
                                          title: task["title"],
                                          status:
                                              task["status"][0].toUpperCase() +
                                              task["status"].substring(1),
                                          statusColor: task["status"] == "todo"
                                              ? Colors.red
                                              : (task["status"] == "In progress"
                                                    ? Colors.orange
                                                    : Colors.green),
                                          requestedBy:
                                              "Assigned by ${task["createdBy"]}",
                                          priority:
                                              task["priority"][0]
                                                  .toUpperCase() +
                                              task["priority"].substring(1),
                                          priorityColor:
                                              task["priority"].toLowerCase() ==
                                                  "high"
                                              ? Colors.red
                                              : Colors.green,
                                          scheduledDate:
                                              DateFormat('yyyy-MM-dd').format(
                                                DateTime.parse(
                                                  task['reportingDate']
                                                          ?.toString() ??
                                                      '',
                                                ),
                                              ),
                                          scheduledTime:
                                              task['reportingTime']
                                                  ?.toString() ??
                                              '',
                                        ),
                                      ),
                                      SizedBox(height: 14.h),
                                      Divider(color: Colors.grey.shade200),
                                    ],

                                    // SizedBox(height: 14.h),
                                    // GestureDetector(
                                    //   onTap: () {
                                    //     Navigator.push(
                                    //       context,
                                    //       MaterialPageRoute(
                                    //         builder: (context) =>
                                    //             TaskDetailScreen(
                                    //               userId: widget.userId,
                                    //               taskId: '2',
                                    //             ),
                                    //       ),
                                    //     );
                                    //   },
                                    //   child: _buildTodoItem(
                                    //     image: "https://i.pravatar.cc/150?img=18",
                                    //     title: "Yearly Food Service",
                                    //     status: "In progress",
                                    //     statusColor: Colors.orange,
                                    //     requestedBy: "Requested by John Kyte",
                                    //     priority: "High",
                                    //     priorityColor: Colors.red,
                                    //   ),
                                    // ),
                                    // SizedBox(height: 14.h),
                                    // Divider(color: Colors.grey.shade200),
                                    // SizedBox(height: 14.h),
                                    // GestureDetector(
                                    //   onTap: () {
                                    //     Navigator.push(
                                    //       context,
                                    //       MaterialPageRoute(
                                    //         builder: (context) =>
                                    //             TaskDetailScreen(
                                    //               userId: widget.userId,
                                    //               taskId: '3',
                                    //             ),
                                    //       ),
                                    //     );
                                    //   },
                                    //   child: _buildTodoItem(
                                    //     image: "https://i.pravatar.cc/150?img=22",
                                    //     title: "Manufacture PM",
                                    //     status: "Done",
                                    //     statusColor: Colors.green,
                                    //     requestedBy:
                                    //         "Requested by Guadalupe Miró",
                                    //     priority: "Low",
                                    //     priorityColor: Colors.green,
                                    //   ),
                                    // ),
                                  ],
                                ),
                              ),
                            ),

                            // /// PAGE 2
                            // Padding(
                            //   padding: const EdgeInsets.symmetric(
                            //     horizontal: 16,
                            //   ),
                            //   child: Column(
                            //     children: [
                            //       GestureDetector(
                            //         onTap: () {
                            //           Navigator.push(
                            //             context,
                            //             MaterialPageRoute(
                            //               builder: (context) =>
                            //                   TaskDetailScreen(
                            //                     userId: widget.userId,
                            //                     taskId: '4',
                            //                   ),
                            //             ),
                            //           );
                            //         },
                            //         child: _buildTodoItem(
                            //           image: "https://i.pravatar.cc/150?img=30",
                            //           title: "Office Cleaning",
                            //           status: "Pending",
                            //           statusColor: Colors.red,
                            //           requestedBy: "Requested by Alex",
                            //           priority: "Low",
                            //           priorityColor: Colors.green,
                            //         ),
                            //       ),
                            //       SizedBox(height: 14.h),
                            //       Divider(color: Colors.grey.shade200),
                            //       SizedBox(height: 14.h),
                            //       GestureDetector(
                            //         onTap: () {
                            //           Navigator.push(
                            //             context,
                            //             MaterialPageRoute(
                            //               builder: (context) =>
                            //                   TaskDetailScreen(
                            //                     userId: widget.userId,
                            //                     taskId: '5',
                            //                   ),
                            //             ),
                            //           );
                            //         },
                            //         child: _buildTodoItem(
                            //           image: "https://i.pravatar.cc/150?img=35",
                            //           title: "Electrical Repair",
                            //           status: "In progress",
                            //           statusColor: Colors.orange,
                            //           requestedBy: "Requested by Smith",
                            //           priority: "High",
                            //           priorityColor: Colors.red,
                            //         ),
                            //       ),
                            //     ],
                            //   ),
                            // ),

                            // /// PAGE 3
                            // Padding(
                            //   padding: const EdgeInsets.symmetric(
                            //     horizontal: 16,
                            //   ),
                            //   child: Column(
                            //     children: [
                            //       GestureDetector(
                            //         onTap: () {
                            //           Navigator.push(
                            //             context,
                            //             MaterialPageRoute(
                            //               builder: (context) =>
                            //                   TaskDetailScreen(
                            //                     userId: widget.userId,
                            //                     taskId: '6',
                            //                   ),
                            //             ),
                            //           );
                            //         },
                            //         child: _buildTodoItem(
                            //           image: "https://i.pravatar.cc/150?img=40",
                            //           title: "Water Supply",
                            //           status: "Done",
                            //           statusColor: Colors.green,
                            //           requestedBy: "Requested by Jacob",
                            //           priority: "Low",
                            //           priorityColor: Colors.green,
                            //         ),
                            //       ),
                            //     ],
                            //   ),
                            // ),
                          ],
                        ),
                      ),

                      /// DOTS
                      // ValueListenableBuilder<int>(
                      //   valueListenable: todoCurrentPageNotifier,
                      //   builder: (context, todoCurrentPage, child) {
                      //     return Row(
                      //       mainAxisAlignment: MainAxisAlignment.center,
                      //       children: List.generate(
                      //         3,
                      //         (index) => GestureDetector(
                      //           onTap: () {
                      //             _todoController.animateToPage(
                      //               index,
                      //               duration: const Duration(milliseconds: 300),
                      //               curve: Curves.easeInOut,
                      //             );
                      //             todoCurrentPageNotifier.value = index;
                      //           },
                      //           child: Padding(
                      //             padding: const EdgeInsets.symmetric(
                      //               horizontal: 3,
                      //             ),
                      //             child: _dot(todoCurrentPage == index),
                      //           ),
                      //         ),
                      //       ),
                      //     );
                      //   },
                      // ),
                    ],
                  ),
                ),

                Container(
                  margin: EdgeInsets.only(left: 15, right: 15, bottom: 15),
                  padding: const EdgeInsets.only(
                    left: 10,
                    right: 10,
                    top: 18,
                    bottom: 14,
                  ),
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      /// TOP HEADER
                      Padding(
                        padding: EdgeInsets.only(left: 16, right: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Overdue",
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0D095B),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 18.h),

                      /// SLIDER
                      SizedBox(
                        height: 300.h,
                        child: PageView(
                          controller: _overdueController,
                          onPageChanged: (index) {
                            overdueCurrentPageNotifier.value = index;
                          },
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    if (_isLoadingOverdueTasks)
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 60.h,
                                        ),
                                        child: Center(
                                          child: SizedBox(
                                            width: 28.w,
                                            height: 28.w,
                                            child: const CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Color(0xFF4338CA),
                                            ),
                                          ),
                                        ),
                                      )
                                    else if (overdueTasks.isEmpty)
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 60.h,
                                        ),
                                        child: Center(
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.check_circle_outline,
                                                size: 40.r,
                                                color: const Color(0xFFB8BEC5),
                                              ),
                                              SizedBox(height: 8.h),
                                              Text(
                                                "No overdue tasks",
                                                style: GoogleFonts.inter(
                                                  fontSize: 13.sp,
                                                  fontWeight: FontWeight.w500,
                                                  color: const Color(
                                                    0xFF9AA0AB,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    else
                                      for (final task in overdueTasks) ...[
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    TaskDetailScreen(
                                                      userId: widget.userId,
                                                      mainTaskId: task["id"],
                                                      taskId:
                                                          task["instanceId"],
                                                    ),
                                              ),
                                            );
                                          },
                                          child: _buildTodoItem(
                                            image: "",
                                            title: task["title"],
                                            status:
                                                task["status"][0]
                                                    .toUpperCase() +
                                                task["status"].substring(1),
                                            statusColor:
                                                task["status"] == "todo"
                                                ? Colors.red
                                                : (task["status"] ==
                                                          "In progress"
                                                      ? Colors.orange
                                                      : Colors.green),
                                            requestedBy:
                                                "Assigned by ${task["createdBy"]}",
                                            priority:
                                                task["priority"][0]
                                                    .toUpperCase() +
                                                task["priority"].substring(1),
                                            priorityColor:
                                                task["priority"]
                                                        .toLowerCase() ==
                                                    "high"
                                                ? Colors.red
                                                : Colors.green,
                                            scheduledDate:
                                                DateFormat('yyyy-MM-dd')
                                                    .format(
                                                      DateTime.parse(
                                                        task['reportingDate']
                                                                ?.toString() ??
                                                            '',
                                                      ),
                                                    ),
                                            scheduledTime:
                                                task['reportingTime']
                                                    ?.toString() ??
                                                '',
                                          ),
                                        ),
                                        SizedBox(height: 14.h),
                                        Divider(color: Colors.grey.shade200),
                                      ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                GestureDetector(
                  onTap: () {},
                  child: Container(
                    margin: EdgeInsets.only(left: 15, right: 15, bottom: 15),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        /// LEFT ICON
                        Container(
                          height: 27.h,
                          width: 30.w,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6.r),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF0F0C8B), Color(0xFF5B46F4)],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Image.asset(
                              width: 20.w,
                              height: 20.h,
                              "assets/images/wrksp3d.png",
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                        SizedBox(width: 10.w),

                        /// TITLE
                        Expanded(
                          child: Text(
                            "Workspaces",
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0D095B),
                            ),
                          ),
                        ),

                        /// RIGHT BUTTON
                        Container(
                          height: 22.h,
                          width: 26.w,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F5FA),
                            borderRadius: BorderRadius.circular(5.r),
                          ),
                          child: Icon(
                            Icons.arrow_forward,
                            size: 15.r,
                            color: Color(0xFF0A0258),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Container(
                  width: double.infinity,
                  clipBehavior: Clip.hardEdge,
                  margin: EdgeInsets.only(left: 15, right: 15, bottom: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.r),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0A0F7A), Color(0xFF1B1F9E)],
                    ),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      /// BACKGROUND SHAPE
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Image.asset(
                          width: 146.w,
                          height: 135.h,
                          "assets/images/wrksprm.png",
                          fit: BoxFit.contain,
                        ),
                      ),

                      /// CONTENT
                      Padding(
                        padding: EdgeInsets.only(
                          top: 15,
                          bottom: 15,
                          left: 15,
                          right: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Need Help?",
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF46BAEB),
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              "Smarter Solutions.\nBetter Results.",
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 10.h),
                            GestureDetector(
                              onTap: () {},
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6.r),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFB26BFF),
                                      Color(0xFF57D5FF),
                                    ],
                                  ),
                                ),
                                child: Text(
                                  "Connect With Us",
                                  style: GoogleFonts.inter(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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

                            /// REPETITIVE
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      modalSetState(() {
                                        selectedWorkspaceType =
                                            selectedWorkspaceType ==
                                                "Repetitive"
                                            ? ""
                                            : "Repetitive";
                                      });
                                    },
                                    child: Row(
                                      children: [
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

                            /// ONE TIME
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      modalSetState(() {
                                        selectedWorkspaceType =
                                            selectedWorkspaceType == "One-time"
                                            ? ""
                                            : "One-time";
                                      });
                                    },
                                    child: Row(
                                      children: [
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

      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 0),
    );
  }

  Widget _buildTodoItem({
    required String image,
    required String title,
    required String status,
    required Color statusColor,
    required String requestedBy,
    required String priority,
    required String scheduledDate,
    required String scheduledTime,
    required Color priorityColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// PROFILE IMAGE
        Stack(
          children: [
            CircleAvatar(
              radius: 18.r,
              backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
              child: image.isEmpty
                  ? Icon(Icons.person, size: 18.r, color: Colors.white70)
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
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0A0258),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    child: Text(
                      status,
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
              Text(
                requestedBy,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF324054),
                ),
              ),

              SizedBox(height: 10.h),

              /// DATE TIME PRIORITY
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14.r,
                    color: Color(0xFF324054),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    scheduledDate,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Color(0xFF324054),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Icon(Icons.access_time, size: 14.r, color: Color(0xFF324054)),
                  SizedBox(width: 4.w),
                  Text(
                    scheduledTime,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Color(0xFF324054),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: 7.h,
                    width: 7.w,
                    decoration: BoxDecoration(
                      color: priorityColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 5.w),
                  Text(
                    priority,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Color(0xFF324054),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// CARD WIDGET
  /// Arrow icon + color reflecting task priority — high points up (urgent,
  /// red), low points down (green), anything else stays neutral (orange).
  Icon _priorityArrowIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Icon(Icons.arrow_upward, size: 12.r, color: Colors.red);
      case 'low':
        return Icon(Icons.arrow_downward, size: 12.r, color: Colors.green);
      default:
        return Icon(Icons.arrow_forward, size: 12.r, color: Colors.orange);
    }
  }

  Widget _buildCard({
    required String number,
    required String title,
    required String scheduledDate,
    required String scheduledTime,
    required String priority,
    required bool isActive,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 8, right: 8),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withOpacity(.40),
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          /// TOP ROW — position number + priority arrow badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                number,
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: isActive ? const Color(0xFF000000) : Colors.grey,
                ),
              ),
              Container(
                height: 20.h,
                width: 20.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(.05),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: _priorityArrowIcon(priority),
              ),
            ],
          ),

          /// TASK NAME
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              height: 1.3,
              fontWeight: FontWeight.w700,
              color: isActive ? const Color(0xFF0A0258) : Colors.grey,
            ),
          ),

          /// SCHEDULE DATE + TIME
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 11.r,
                color: isActive ? const Color(0xFF16105D) : Colors.grey,
              ),
              SizedBox(width: 4.w),
              Flexible(
                child: Text(
                  scheduledDate,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: isActive ? const Color(0xFF16105D) : Colors.grey,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Icon(
                Icons.access_time,
                size: 11.r,
                color: isActive ? const Color(0xFF16105D) : Colors.grey,
              ),
              SizedBox(width: 4.w),
              Flexible(
                child: Text(
                  scheduledTime,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: isActive ? const Color(0xFF16105D) : Colors.grey,
                  ),
                ),
              ),
            ],
          ),

          /// BOTTOM ICON
          Align(
            alignment: Alignment.bottomRight,
            child: Icon(
              Icons.arrow_forward_ios,
              size: 12.r,
              color: isActive ? const Color(0xFF16105D) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// DOT INDICATOR
  Widget _dot(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 6,
      width: active ? 18 : 6,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF5B46F4) : const Color(0xFFC9C5D6),
        borderRadius: BorderRadius.circular(20.r),
      ),
    );
  }

  Widget _buildWorkspaceOption({
    required String title,
    required String value,
    required String selectedValue,
    required VoidCallback onSelect,
    required VoidCallback onArrowTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onSelect,
            child: Row(
              children: [
                Container(
                  width: 18.w,
                  height: 18.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF4338CA),
                      width: 1.3,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 10.w,
                      height: 10.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selectedValue == value
                            ? const Color(0xFF24116A)
                            : Colors.transparent,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF344054),
                  ),
                ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: onArrowTap,
          child: Container(
            width: 30.w,
            height: 30.w,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F7),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.arrow_forward,
              size: 18.r,
              color: const Color(0xFF667085),
            ),
          ),
        ),
      ],
    );
  }
}
