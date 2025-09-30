import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/chat_service.dart';
import '../services/attendance_service.dart';
import '../models/chat_message.dart';
import '../models/attendance_record.dart';

/// Provider for ChatService
final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

/// Provider for AttendanceService
final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  return AttendanceService();
});

/// Provider for user's chat conversations
final userConversationsProvider = StreamProvider<List<ChatConversation>>((ref) {
  final chatService = ref.read(chatServiceProvider);
  return chatService.getUserConversations();
});

/// Provider for current conversation ID
final currentConversationIdProvider = StateProvider<String?>((ref) => null);

/// Provider for messages in current conversation
final conversationMessagesProvider = StreamProvider<List<ChatMessage>>((ref) {
  final conversationId = ref.watch(currentConversationIdProvider);
  if (conversationId == null) return Stream.value([]);

  final chatService = ref.read(chatServiceProvider);
  return chatService.getConversationMessages(conversationId);
});

/// Provider for all attendance records
final allAttendanceProvider = StreamProvider<List<AttendanceRecord>>((ref) {
  final attendanceService = ref.read(attendanceServiceProvider);
  return attendanceService.getAllAttendance();
});

/// Provider for course attendance (requires courseId parameter)
final courseAttendanceProvider =
    StreamProvider.family<List<AttendanceRecord>, String>((ref, courseId) {
      final attendanceService = ref.read(attendanceServiceProvider);
      return attendanceService.getCourseAttendance(courseId).handleError((
        error,
      ) {
        print('ERROR in courseAttendanceProvider: $error');
        // Return empty list on error to prevent UI crashes
        return <AttendanceRecord>[];
      });
    });

/// Provider for course attendance statistics
final courseAttendanceStatsProvider =
    FutureProvider.family<AttendanceStats, String>((ref, courseId) async {
      final attendanceService = ref.read(attendanceServiceProvider);
      return attendanceService.getCourseStats(courseId);
    });

/// Provider for today's attendance
final todayAttendanceProvider = StreamProvider<List<AttendanceRecord>>((ref) {
  final attendanceService = ref.read(attendanceServiceProvider);
  return attendanceService.getTodayAttendance();
});

/// Provider for checking if attendance is marked today for a course
final isAttendanceMarkedTodayProvider = FutureProvider.family<bool, String>((
  ref,
  courseId,
) {
  final attendanceService = ref.read(attendanceServiceProvider);
  return attendanceService.isAttendanceMarkedToday(courseId);
});

/// Chat actions provider for managing chat operations
final chatActionsProvider = Provider<ChatActions>((ref) {
  final chatService = ref.read(chatServiceProvider);
  return ChatActions(chatService, ref);
});

/// Attendance actions provider for managing attendance operations
final attendanceActionsProvider = Provider<AttendanceActions>((ref) {
  final attendanceService = ref.read(attendanceServiceProvider);
  return AttendanceActions(attendanceService, ref);
});

/// Chat actions class for encapsulating chat operations
class ChatActions {
  final ChatService _chatService;
  final ProviderRef _ref;

  ChatActions(this._chatService, this._ref);

  /// Initialize or get default conversation
  Future<void> initializeChat() async {
    try {
      final conversationId =
          await _chatService.getOrCreateDefaultConversation();
      _ref.read(currentConversationIdProvider.notifier).state = conversationId;
    } catch (e) {
      print('Error initializing chat: $e');
    }
  }

  /// Send a message
  Future<void> sendMessage(String text, bool isUser) async {
    final conversationId = _ref.read(currentConversationIdProvider);
    if (conversationId == null) {
      await initializeChat();
      final newConversationId = _ref.read(currentConversationIdProvider);
      if (newConversationId == null) return;
    }

    final activeConversationId = _ref.read(currentConversationIdProvider)!;
    await _chatService.addMessage(
      conversationId: activeConversationId,
      text: text,
      isUser: isUser,
    );
  }

  /// Create new conversation
  Future<void> createNewConversation() async {
    final conversationId = await _chatService.createConversation();
    _ref.read(currentConversationIdProvider.notifier).state = conversationId;
  }

  /// Switch to a different conversation
  void switchConversation(String conversationId) {
    _ref.read(currentConversationIdProvider.notifier).state = conversationId;
  }

  /// Delete a conversation
  Future<void> deleteConversation(String conversationId) async {
    await _chatService.deleteConversation(conversationId);

    // If we deleted the current conversation, clear it
    final currentId = _ref.read(currentConversationIdProvider);
    if (currentId == conversationId) {
      _ref.read(currentConversationIdProvider.notifier).state = null;
    }
  }
}

/// Attendance actions class for encapsulating attendance operations
class AttendanceActions {
  final AttendanceService _attendanceService;
  final ProviderRef _ref;

  AttendanceActions(this._attendanceService, this._ref);

  /// Mark attendance for a course
  Future<void> markAttendance({
    required String courseId,
    required String courseName,
    required AttendanceStatus status,
    String? notes,
  }) async {
    await _attendanceService.markAttendance(
      courseId: courseId,
      courseName: courseName,
      status: status,
      notes: notes,
    );
  }

  /// Update existing attendance record
  Future<void> updateAttendance(
    String recordId,
    AttendanceStatus status, {
    String? notes,
  }) async {
    await _attendanceService.updateAttendance(recordId, status, notes: notes);
  }

  /// Delete attendance record
  Future<void> deleteAttendance(String recordId) async {
    await _attendanceService.deleteAttendance(recordId);
  }
}
