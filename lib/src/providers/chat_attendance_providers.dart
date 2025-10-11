import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/chat_service.dart';
import '../services/attendance_service.dart';
import '../models/chat_message.dart';
import '../models/attendance_record.dart';
import '../models/course.dart';
import '../services/model_selection.dart';

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
  return AttendanceActions(attendanceService);
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
      // Load saved model for this conversation if present
      final convo = await _chatService.getConversation(conversationId);
      final modelId = convo?.modelId;
      if (modelId != null && modelId.isNotEmpty) {
        // ignore: avoid_async_in_sync
        _ref.read(selectedModelIdProvider.notifier).setModel(modelId);
      }
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
    // If this is the user's first message, set a helpful title from it
    if (isUser) {
      await _chatService.maybeSetTitleFromFirstMessage(
        activeConversationId,
        text,
      );
    }
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
    // Fire-and-forget: apply the conversation's model to selection if set
    _chatService.getConversation(conversationId).then((convo) {
      final modelId = convo?.modelId;
      if (modelId != null && modelId.isNotEmpty) {
        _ref.read(selectedModelIdProvider.notifier).setModel(modelId);
      }
    });
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

  /// Rename a conversation (e.g., via sidebar overflow menu)
  Future<void> renameConversation(String conversationId, String title) async {
    await _chatService.updateConversationTitle(conversationId, title);
  }

  /// Persist selected model for the current conversation (optional)
  Future<void> setConversationModel(String modelId) async {
    final id = _ref.read(currentConversationIdProvider);
    if (id == null) return;
    await _chatService.updateConversationModel(id, modelId);
  }
}

/// Attendance actions class for encapsulating attendance operations
class AttendanceActions {
  final AttendanceService _attendanceService;
  AttendanceActions(this._attendanceService);

  /// Mark attendance for a course with validation
  Future<void> markAttendance({
    required String courseId,
    required String courseName,
    required AttendanceStatus status,
    String? notes,
    Course? course, // Optional: for schedule validation
    DateTime? date, // Optional: defaults to now
  }) async {
    await _attendanceService.markAttendance(
      courseId: courseId,
      courseName: courseName,
      status: status,
      notes: notes,
      course: course,
      date: date,
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
