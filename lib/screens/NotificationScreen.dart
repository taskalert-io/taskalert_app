import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import '../components/CustomAppBar.dart';
import '../components/CustomBottomNavBar.dart';
import '../components/CustomDrawer.dart';
import '../components/ToggleSwitch.dart';

// ── Notification toggle keys (use these as API field names) ─────────────────
// Communications
const String kNotifMentionedMe               = 'notif_mentioned_me';
const String kNotifWroteUpdateOwned          = 'notif_wrote_update_owned';
const String kNotifWroteUpdateSubscribed     = 'notif_wrote_update_subscribed';
const String kNotifRepliedThread             = 'notif_replied_thread';
const String kNotifRepliedMyUpdate           = 'notif_replied_my_update';
const String kNotifReactions                 = 'notif_reactions';
// Automation
const String kNotifAutomationNotify          = 'notif_automation_notify';
const String kNotifAutomationFailures        = 'notif_automation_failures';
const String kNotifPlatformApi               = 'notif_platform_api';
// Collaboration
const String kNotifAssignedMe                = 'notif_assigned_me';
const String kNotifInvitations               = 'notif_invitations';
const String kNotifTemplateChanges           = 'notif_template_changes';
// Requests
const String kNotifRequestsAccess            = 'notif_requests_access';
const String kNotifRequestsInstallation      = 'notif_requests_installation';
// Admin
const String kNotifMemberRemoved             = 'notif_automatic_plan_upgrade';
const String kNotifNewMemberJoined           = 'notif_signed_up';
const String kNotifPendingRequest            = 'notif_pending_inventing_request';
const String kNotifUsageWarning              = 'notif_ai_usage_warning';
const String kNotifCreditLimit               = 'notif_ai_credit_limit_active';
const String kNotifCreditStop                = 'notif_ai_credit_limit_stopped';
const String kNotifCreditRequest             = 'notif_ai_credit_request_active';
const String kNotifCreditRequestStopped      = 'notif_ai_credit_request_stopped';
// Sign-ups
const String kNotifNewSignUp                 = 'notif_new_sign_up';
const String kNotifDidnotSignUp                 = 'notif_ddnt_sign_up';
// Security
const String kNotifViolatinSummery            = 'notif_Violation_summary';
const String kNotiFileDeleted           = 'notif_file_deleted';
const String kNotifUpdateDeletedReducted           = 'notif_update_deleted_reducted';

// ── Data models ──────────────────────────────────────────────────────────────

class NotifItem {
  final String key;
  final String title;
  final String desc;
  final IconData? prtIcon;

  const NotifItem({
    required this.key,
    required this.title,
    required this.desc,
    this.prtIcon,
  });
}

class NotifTab {
  final String label;
  final List<NotifItem> items;
  const NotifTab({required this.label, required this.items});
}

// ── Screen ───────────────────────────────────────────────────────────────────

class NotificationSetting extends StatefulWidget {
  final String userId;
  const NotificationSetting({super.key, required this.userId});

  @override
  State<NotificationSetting> createState() => _NotificationSettingState();
}

class _NotificationSettingState extends State<NotificationSetting> {
  static const _primaryColor  = Color(0xFF0A0258);
  static const _dividerColor  = Color(0xFFE4E7EC);
  static const _textColor     = Color(0xFF6C7278);
  static const _labelColor    = Color(0xFF303030);
  static const _shadowBlack08 = Color(0x14000000);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  int _selectedTab = 0;

  // ── Individual toggle state variables ─────────────────────────────────────
  // Communications
  bool notif_mentioned_me               = false;
  bool notif_wrote_update_owned         = true;
  bool notif_wrote_update_subscribed    = false;
  bool notif_replied_thread             = true;
  bool notif_replied_my_update          = false;
  bool notif_reactions                  = false;
  // Automation
  bool notif_automation_notify          = false;
  bool notif_automation_failures        = false;
  bool notif_platform_api               = true;
  // Collaboration
  bool notif_assigned_me                = false;
  bool notif_invitations                = true;
  bool notif_template_changes           = false;
  // Requests
  bool notif_requests_access            = false;
  bool notif_requests_installation      = false;
  // Admin
  bool notif_automatic_plan_upgrade     = false;
  bool notif_signed_up                  = true;
  bool notif_pending_inventing_request  = true;
  bool notif_ai_usage_warning           = false;
  bool notif_ai_credit_limit_active     = true;
  bool notif_ai_credit_limit_stopped    = false;
  bool notif_ai_credit_request_active   = false;
  bool notif_ai_credit_request_stopped  = false;
  // Sign-ups
  bool notif_new_sign_up                = true;
  bool notif_ddnt_sign_up                = false;
  // Security
  bool notif_login_new_device           = true;
  bool notif_password_changed           = true;
  bool notif_Violation_summary           = true;
  bool notif_file_deleted           = false;
  bool notif_update_deleted_reducted           = false;

  // ── Helper: get current value for a key ───────────────────────────────────
  bool _getValue(String key) {
    switch (key) {
      case kNotifMentionedMe:              return notif_mentioned_me;
      case kNotifWroteUpdateOwned:         return notif_wrote_update_owned;
      case kNotifWroteUpdateSubscribed:    return notif_wrote_update_subscribed;
      case kNotifRepliedThread:            return notif_replied_thread;
      case kNotifRepliedMyUpdate:          return notif_replied_my_update;
      case kNotifReactions:                return notif_reactions;
      case kNotifAutomationNotify:         return notif_automation_notify;
      case kNotifAutomationFailures:       return notif_automation_failures;
      case kNotifPlatformApi:              return notif_platform_api;
      case kNotifAssignedMe:               return notif_assigned_me;
      case kNotifInvitations:              return notif_invitations;
      case kNotifTemplateChanges:          return notif_template_changes;
      case kNotifRequestsAccess:           return notif_requests_access;
      case kNotifRequestsInstallation:     return notif_requests_installation;
      case kNotifMemberRemoved:            return notif_automatic_plan_upgrade;
      case kNotifNewMemberJoined:          return notif_signed_up;
      case kNotifPendingRequest:           return notif_pending_inventing_request;
      case kNotifUsageWarning:             return notif_ai_usage_warning;
      case kNotifCreditLimit:              return notif_ai_credit_limit_active;
      case kNotifCreditStop:               return notif_ai_credit_limit_stopped;
      case kNotifCreditRequest:            return notif_ai_credit_request_active;
      case kNotifCreditRequestStopped:     return notif_ai_credit_request_stopped;
      case kNotifNewSignUp:                return notif_new_sign_up;
      case kNotifDidnotSignUp:                return notif_ddnt_sign_up;
      case kNotifViolatinSummery:           return notif_Violation_summary;
      case kNotiFileDeleted:          return notif_file_deleted;
      case kNotifUpdateDeletedReducted:          return notif_update_deleted_reducted;
      default:                             return false;
    }
  }

  // ── Helper: toggle a value by key ─────────────────────────────────────────
  void _toggleValue(String key) {
    setState(() {
      switch (key) {
        case kNotifMentionedMe:           notif_mentioned_me              = !notif_mentioned_me;              break;
        case kNotifWroteUpdateOwned:      notif_wrote_update_owned        = !notif_wrote_update_owned;        break;
        case kNotifWroteUpdateSubscribed: notif_wrote_update_subscribed   = !notif_wrote_update_subscribed;   break;
        case kNotifRepliedThread:         notif_replied_thread            = !notif_replied_thread;            break;
        case kNotifRepliedMyUpdate:       notif_replied_my_update         = !notif_replied_my_update;         break;
        case kNotifReactions:             notif_reactions                 = !notif_reactions;                 break;
        case kNotifAutomationNotify:      notif_automation_notify         = !notif_automation_notify;         break;
        case kNotifAutomationFailures:    notif_automation_failures       = !notif_automation_failures;       break;
        case kNotifPlatformApi:           notif_platform_api              = !notif_platform_api;              break;
        case kNotifAssignedMe:            notif_assigned_me               = !notif_assigned_me;               break;
        case kNotifInvitations:           notif_invitations               = !notif_invitations;               break;
        case kNotifTemplateChanges:       notif_template_changes          = !notif_template_changes;          break;
        case kNotifRequestsAccess:        notif_requests_access           = !notif_requests_access;           break;
        case kNotifRequestsInstallation:  notif_requests_installation     = !notif_requests_installation;     break;
        case kNotifMemberRemoved:         notif_automatic_plan_upgrade    = !notif_automatic_plan_upgrade;    break;
        case kNotifNewMemberJoined:       notif_signed_up                 = !notif_signed_up;                 break;
        case kNotifPendingRequest:        notif_pending_inventing_request = !notif_pending_inventing_request; break;
        case kNotifUsageWarning:          notif_ai_usage_warning          = !notif_ai_usage_warning;          break;
        case kNotifCreditLimit:           notif_ai_credit_limit_active    = !notif_ai_credit_limit_active;    break;
        case kNotifCreditStop:            notif_ai_credit_limit_stopped   = !notif_ai_credit_limit_stopped;   break;
        case kNotifCreditRequest:         notif_ai_credit_request_active  = !notif_ai_credit_request_active;  break;
        case kNotifCreditRequestStopped:  notif_ai_credit_request_stopped = !notif_ai_credit_request_stopped; break;
        case kNotifNewSignUp:             notif_new_sign_up               = !notif_new_sign_up;               break;
        case kNotifDidnotSignUp:             notif_ddnt_sign_up               = !notif_ddnt_sign_up;               break;
        case kNotifViolatinSummery:        notif_Violation_summary          = !notif_Violation_summary;          break;
        case kNotiFileDeleted:       notif_file_deleted          = !notif_file_deleted;          break;
        case kNotifUpdateDeletedReducted:       notif_update_deleted_reducted          = !notif_update_deleted_reducted;          break;
      }
    });
    // Future: _patchNotificationSetting(key, _getValue(key));
  }

  // ── API helpers ────────────────────────────────────────────────────────────
  Map<String, bool> _toApiPayload() => {
    kNotifMentionedMe:           notif_mentioned_me,
    kNotifWroteUpdateOwned:      notif_wrote_update_owned,
    kNotifWroteUpdateSubscribed: notif_wrote_update_subscribed,
    kNotifRepliedThread:         notif_replied_thread,
    kNotifRepliedMyUpdate:       notif_replied_my_update,
    kNotifReactions:             notif_reactions,
    kNotifAutomationNotify:      notif_automation_notify,
    kNotifAutomationFailures:    notif_automation_failures,
    kNotifPlatformApi:           notif_platform_api,
    kNotifAssignedMe:            notif_assigned_me,
    kNotifInvitations:           notif_invitations,
    kNotifTemplateChanges:       notif_template_changes,
    kNotifRequestsAccess:        notif_requests_access,
    kNotifRequestsInstallation:  notif_requests_installation,
    kNotifMemberRemoved:         notif_automatic_plan_upgrade,
    kNotifNewMemberJoined:       notif_signed_up,
    kNotifPendingRequest:        notif_pending_inventing_request,
    kNotifUsageWarning:          notif_ai_usage_warning,
    kNotifCreditLimit:           notif_ai_credit_limit_active,
    kNotifCreditStop:            notif_ai_credit_limit_stopped,
    kNotifCreditRequest:         notif_ai_credit_request_active,
    kNotifCreditRequestStopped:  notif_ai_credit_request_stopped,
    kNotifNewSignUp:             notif_new_sign_up,
    kNotifDidnotSignUp:             notif_ddnt_sign_up,
    kNotifViolatinSummery:        notif_Violation_summary,
    kNotiFileDeleted:       notif_file_deleted,
    kNotifUpdateDeletedReducted:       notif_update_deleted_reducted,
  };

  void _applyApiPayload(Map<String, bool> data) {
    setState(() {
      notif_mentioned_me              = data[kNotifMentionedMe]           ?? notif_mentioned_me;
      notif_wrote_update_owned        = data[kNotifWroteUpdateOwned]      ?? notif_wrote_update_owned;
      notif_wrote_update_subscribed   = data[kNotifWroteUpdateSubscribed] ?? notif_wrote_update_subscribed;
      notif_replied_thread            = data[kNotifRepliedThread]         ?? notif_replied_thread;
      notif_replied_my_update         = data[kNotifRepliedMyUpdate]       ?? notif_replied_my_update;
      notif_reactions                 = data[kNotifReactions]             ?? notif_reactions;
      notif_automation_notify         = data[kNotifAutomationNotify]      ?? notif_automation_notify;
      notif_automation_failures       = data[kNotifAutomationFailures]    ?? notif_automation_failures;
      notif_platform_api              = data[kNotifPlatformApi]           ?? notif_platform_api;
      notif_assigned_me               = data[kNotifAssignedMe]            ?? notif_assigned_me;
      notif_invitations               = data[kNotifInvitations]           ?? notif_invitations;
      notif_template_changes          = data[kNotifTemplateChanges]       ?? notif_template_changes;
      notif_requests_access           = data[kNotifRequestsAccess]        ?? notif_requests_access;
      notif_requests_installation     = data[kNotifRequestsInstallation]  ?? notif_requests_installation;
      notif_automatic_plan_upgrade    = data[kNotifMemberRemoved]         ?? notif_automatic_plan_upgrade;
      notif_signed_up                 = data[kNotifNewMemberJoined]       ?? notif_signed_up;
      notif_pending_inventing_request = data[kNotifPendingRequest]        ?? notif_pending_inventing_request;
      notif_ai_usage_warning          = data[kNotifUsageWarning]          ?? notif_ai_usage_warning;
      notif_ai_credit_limit_active    = data[kNotifCreditLimit]           ?? notif_ai_credit_limit_active;
      notif_ai_credit_limit_stopped   = data[kNotifCreditStop]            ?? notif_ai_credit_limit_stopped;
      notif_ai_credit_request_active  = data[kNotifCreditRequest]         ?? notif_ai_credit_request_active;
      notif_ai_credit_request_stopped = data[kNotifCreditRequestStopped]  ?? notif_ai_credit_request_stopped;
      notif_new_sign_up               = data[kNotifNewSignUp]             ?? notif_new_sign_up;
      notif_ddnt_sign_up               = data[kNotifDidnotSignUp]             ?? notif_ddnt_sign_up;
      notif_Violation_summary          = data[kNotifViolatinSummery]        ?? notif_Violation_summary;
      notif_file_deleted          = data[kNotiFileDeleted]       ?? notif_file_deleted;
      notif_update_deleted_reducted          = data[kNotifUpdateDeletedReducted]       ?? notif_update_deleted_reducted;
    });
  }

  // ── Static tab structure ───────────────────────────────────────────────────
  static const List<NotifTab> _tabs = [
    NotifTab(label: 'Communications', items: [
      NotifItem(key: kNotifMentionedMe,           title: 'Mentioned me',    desc: 'in an update or reply'),
      NotifItem(
        key:     kNotifWroteUpdateOwned,
        title:   'Wrote an update',
        desc:    'on an item I own',
        prtIcon: Icons.info_outline,
      ),
      NotifItem(key: kNotifWroteUpdateSubscribed, title: 'Wrote an update', desc: "on an item I'm subscribed to"),
      NotifItem(key: kNotifRepliedThread,         title: 'Replied',         desc: 'to a thread I commented on or reached to'),
      NotifItem(key: kNotifRepliedMyUpdate,       title: 'Replied',         desc: 'to an update I wrote'),
      NotifItem(key: kNotifReactions,             title: 'Reactions',       desc: 'to my update'),
    ]),
    NotifTab(label: 'Automation', items: [
      NotifItem(key: kNotifAutomationNotify,   title: 'Automations with a "notify" step', desc: 'this does not include "send an email" automations'),
      NotifItem(key: kNotifAutomationFailures, title: 'Automation failures',              desc: "when automations don't run as expected"),
      NotifItem(key: kNotifPlatformApi,        title: 'Platform API',                     desc: 'Custom notifications using the GraphQL API'),
    ]),
    NotifTab(label: 'Collaboration', items: [
      NotifItem(key: kNotifAssignedMe,      title: 'Assigned me',      desc: 'to an item'),
      NotifItem(key: kNotifInvitations,     title: 'Invitations',      desc: 'to workspace, board, doc, item or team'),
      NotifItem(key: kNotifTemplateChanges, title: 'Template changes', desc: 'by the template owner'),
    ]),
    NotifTab(label: 'Requests', items: [
      NotifItem(key: kNotifRequestsAccess,       title: 'Requests access',       desc: 'to boards & dashboards'),
      NotifItem(key: kNotifRequestsInstallation, title: 'Requests installation', desc: 'to install & purchase apps'),
    ]),
    NotifTab(label: 'Admin', items: [
      NotifItem(key: kNotifMemberRemoved,        title: 'Automatic plan upgrade',      desc: 'when an automatic plan upgrade is scheduled to occur'),
      NotifItem(key: kNotifNewMemberJoined,      title: 'Signed up',                   desc: 'with an email address from my account domain'),
      NotifItem(key: kNotifPendingRequest,       title: 'Pending invite requests',     desc: 'when invite request have been pending for over 7 days.'),
      NotifItem(key: kNotifUsageWarning,         title: 'AI Usage Warning',            desc: 'notify when ai usage exceeds 80%'),
      NotifItem(key: kNotifCreditLimit,          title: 'AI Credit Limit (Active)',    desc: 'notify when the limit is reached but AI features keep running'),
      NotifItem(key: kNotifCreditStop,           title: 'AI Credit Limit (Stopped)',   desc: 'notify when 100% usage is reached and AI features stop'),
      NotifItem(key: kNotifCreditRequest,        title: 'AI Credit Request (Active)',  desc: 'notify when a user requests credits while AI features are still running'),
      NotifItem(key: kNotifCreditRequestStopped, title: 'AI Credit Request (Stopped)', desc: 'notify when a user requests credits after usage has stopped'),
    ]),
    NotifTab(label: 'Sign-ups', items: [
      NotifItem(key: kNotifNewSignUp, title: 'Signed up', desc: 'after I have invited them'),
      NotifItem(key: kNotifDidnotSignUp, title: 'Didn’t sign up', desc: 'after I have invited them'),
    ]),
    NotifTab(label: 'Security', items: [
      NotifItem(key: kNotifViolatinSummery,  title: 'Violation summaries', desc: 'for breaching data Policies'),
      NotifItem(key: kNotiFileDeleted, title: 'File has been deleted',      desc: 'for breaching data Policies'),
      NotifItem(key: kNotifUpdateDeletedReducted, title: 'Update has been deleted or redacted',      desc: 'for breaching data Policies'),
    ]),
  ];

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _buildTab(String label, bool isSelected) {
    return IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: isSelected ? _primaryColor : const Color(0xFF8B8C8E),
              ),
            ),
          ),
          SizedBox(height: 3.h),
          Container(
            width: double.infinity,
            height: 3.h,
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                colors: [Color(0xFFE040FB), Color(0xFF40C4FF), Color(0xFF64FFDA)],
              )
                  : null,
              color: isSelected ? null : const Color(0xFFE5E5E5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifRow(NotifItem item, int itemIdx) {
    final value = _getValue(item.key);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (itemIdx != 0) const Divider(height: 1, color: _dividerColor),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.notifications_none_outlined, size: 20.r, color: _textColor),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            item.title,
                            style: GoogleFonts.inter(
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w600,
                              color: _labelColor,
                            ),
                          ),
                        ),
                        if (item.prtIcon != null) ...[
                          SizedBox(width: 4.w),
                          Icon(item.prtIcon, size: 14.r, color: _textColor),
                        ],
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      item.desc,
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w400,
                        color: _textColor,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              ToggleSwitch(
                value: value,
                semanticLabel: item.title,
                onTap: () => _toggleValue(item.key),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotifCard() {
    final tab = _tabs[_selectedTab];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(color: _shadowBlack08, blurRadius: 4, offset: const Offset(0, 1)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 16.h),
            child: Text(
              tab.label,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: _primaryColor,
              ),
            ),
          ),
          ...List.generate(tab.items.length, (i) => _buildNotifRow(tab.items[i], i)),
          SizedBox(height: 4.h),
        ],
      ),
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
            Padding(
              padding: EdgeInsets.fromLTRB(15.w, 10.h, 15.w, 16.h),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Text(
                      'Notification Settings',
                      style: GoogleFonts.inter(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: _primaryColor,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.arrow_back, size: 20.r, color: _primaryColor),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 36.h,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 15.w),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(_tabs.length, (i) {
                    return GestureDetector(
                      onTap: () => setState(() => _selectedTab = i),
                      child: Padding(
                        padding: EdgeInsets.only(right: i < _tabs.length - 1 ? 20.w : 0),
                        child: _buildTab(_tabs[i].label, _selectedTab == i),
                      ),
                    );
                  }),
                ),
              ),
            ),
            SizedBox(height: 14.h),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(left: 15.w, right: 15.w, bottom: 16.h),
                child: Column(
                  children: [
                    _buildNotifCard(),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: -1),
    );
  }
}