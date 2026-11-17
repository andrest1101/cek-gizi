import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cekgizi/core/config/app_config.dart';
import 'package:cekgizi/core/supabase/supabase_client_provider.dart';
import 'package:cekgizi/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:cekgizi/features/chat/domain/entities/assistant_reply.dart';
import 'package:cekgizi/features/chat/domain/entities/chat_message.dart';
import 'package:cekgizi/features/chat/domain/repositories/chat_repository.dart';
import 'package:cekgizi/features/chat/domain/usecases/chat_use_cases.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepositoryImpl(ref.watch(supabaseClientProvider)),
);

/// Sisa kuota Tanya Gizi hari ini (Asia/Jakarta). `null` = tidak bisa
/// dibaca (badge disembunyikan). Nilai ini hanya untuk tampilan; kuota
/// sebenarnya ditegakkan server di Edge Function (PRD §5.4/5.5).
final remainingChatQuotaProvider = FutureProvider<int?>((ref) async {
  final used = await ChatUseCases.usageToday(ref.watch(chatRepositoryProvider));
  if (used == null) return null;
  return (AppConfig.chatDailyLimit - used).clamp(0, AppConfig.chatDailyLimit);
});

/// Status satu percakapan Tanya Gizi.
///
/// [messages] diurutkan dari yang TERBARU ke terlama (langsung dipakai
/// `ListView(reverse: true)`). [followups] adalah pertanyaan lanjutan dari
/// jawaban terakhir - tidak disimpan di DB, jadi hanya hidup selama sesi.
final class ChatMessagesState {
  const ChatMessagesState({
    this.messages = const [],
    this.sending = false,
    this.sendError,
    this.pendingQuestion,
    this.historySyncFailed = false,
    this.followups = const [],
  });

  final List<ChatMessage> messages;
  final bool sending;

  /// Kode PRD §5.5 (`quota_daily`, `timeout`, `ai_unavailable`, `offline`,
  /// `unauthorized`, `invalid_input`) untuk kartu error di layar.
  final String? sendError;

  /// Pertanyaan terakhir yang gagal/tersendat - dipakai tombol "Coba lagi".
  final String? pendingQuestion;

  /// `true` bila jawaban sudah tampil tapi penyimpanan riwayat gagal;
  /// layar menampilkan baris peringatan + aksi "Simpan lagi".
  final bool historySyncFailed;

  final List<String> followups;

  ChatMessagesState copyWith({
    List<ChatMessage>? messages,
    bool? sending,
    String? sendError,
    String? pendingQuestion,
    bool? historySyncFailed,
    List<String>? followups,
    bool clearSendError = false,
    bool clearPendingQuestion = false,
  }) {
    return ChatMessagesState(
      messages: messages ?? this.messages,
      sending: sending ?? this.sending,
      sendError: clearSendError ? null : sendError ?? this.sendError,
      pendingQuestion: clearPendingQuestion
          ? null
          : pendingQuestion ?? this.pendingQuestion,
      historySyncFailed: historySyncFailed ?? this.historySyncFailed,
      followups: followups ?? this.followups,
    );
  }
}

/// Orkestrasi kirim/muat/hapus riwayat Tanya Gizi.
///
/// Penulisan ke `chat_messages` bersifat non-kritikal untuk tampilan:
/// jika jawaban sudah tampil tapi penyimpanan gagal, [historySyncFailed]
/// diset dan [retrySync] bisa dipanggil untuk mencoba lagi TANPA memanggil
/// AI ulang (kuota tidak dihanguskan dua kali).
class ChatNotifier extends AsyncNotifier<ChatMessagesState> {
  @override
  Future<ChatMessagesState> build() async {
    final messages = await ChatUseCases.listMessages(
      ref.watch(chatRepositoryProvider),
    );
    return ChatMessagesState(messages: messages.reversed.toList());
  }

  /// Kirim pertanyaan. Dipanggil dari UI dengan teks mentah; validasi dan
  /// pemotongan konteks (maks 10 pesan) ada di [ChatUseCases.askQuestion].
  Future<void> sendQuestion(String question) async {
    final current = state.value;
    if (current == null || current.sending) return;
    final text = question.trim();
    if (text.isEmpty) return;

    final pendingUser = ChatMessage(
      id: '',
      role: ChatRole.user,
      content: text,
      safetyFlag: ChatSafetyFlag.none,
      createdAt: DateTime.now(),
    );
    state = AsyncData(
      current.copyWith(
        messages: [pendingUser, ...current.messages],
        sending: true,
        followups: const [],
        clearSendError: true,
      ),
    );

    try {
      final child = ref.read(selectedChildProvider).value;
      if (child == null) {
        throw const ChatException('invalid_input');
      }
      final chronological = state.value!.messages.reversed.toList();
      final result = await ChatUseCases.askQuestion(
        ref.read(chatRepositoryProvider),
        messages: chronological,
        ageMonths: child.ageInCompletedMonths(DateTime.now()),
        sex: child.sex.dbValue,
      );
      final pendingReply = ChatMessage(
        id: '',
        role: ChatRole.assistant,
        content: result.answer,
        safetyFlag: result.safetyFlag,
        createdAt: DateTime.now(),
      );
      final afterReply = state.value;
      if (afterReply == null) return;
      state = AsyncData(
        afterReply.copyWith(
          messages: [pendingReply, ...afterReply.messages],
          sending: false,
          followups: result.followups,
          clearPendingQuestion: true,
        ),
      );
      // Kuota berubah setelah ask berhasil (kecuali red flag, yang tidak
      // memakai kuota) - segarkan badge.
      ref.invalidate(remainingChatQuotaProvider);

      try {
        await _persistExchange(user: pendingUser, reply: pendingReply);
      } catch (_) {
        final latest = state.value;
        if (latest != null) {
          state = AsyncData(latest.copyWith(historySyncFailed: true));
        }
      }
    } on ChatException catch (exception) {
      final latest = state.value;
      if (latest == null) return;
      state = AsyncData(
        latest.copyWith(
          messages: latest.messages
              .where((message) => !identical(message, pendingUser))
              .toList(),
          sending: false,
          sendError: exception.code,
          pendingQuestion: text,
        ),
      );
      if (exception.code == 'quota_daily') {
        ref.invalidate(remainingChatQuotaProvider);
      }
    } catch (_) {
      final latest = state.value;
      if (latest == null) return;
      state = AsyncData(
        latest.copyWith(
          messages: latest.messages
              .where((message) => !identical(message, pendingUser))
              .toList(),
          sending: false,
          sendError: 'offline',
          pendingQuestion: text,
        ),
      );
    }
  }

  /// Ulangi pertanyaan terakhir yang gagal (tanpa menggandakan bubble).
  Future<void> retrySend() async {
    final pending = state.value?.pendingQuestion;
    if (pending == null) return;
    await sendQuestion(pending);
  }

  /// Coba simpan ulang pasangan pesan yang belum tersimpan (mis. setelah
  /// koneksi pulih). Tidak memanggil AI lagi.
  Future<void> retrySync() async {
    final current = state.value;
    if (current == null) return;
    final unsaved = current.messages.where((m) => m.id.isEmpty).toList();
    if (unsaved.isEmpty) {
      state = AsyncData(current.copyWith(historySyncFailed: false));
      return;
    }
    final repo = ref.read(chatRepositoryProvider);
    final childId = ref.read(selectedChildProvider).value?.id;
    try {
      final saved = <ChatMessage>[];
      for (final message in unsaved.reversed.toList()) {
        saved.add(
          await repo.addMessage(
            role: message.role,
            content: message.content,
            safetyFlag: message.safetyFlag,
            childId: childId,
          ),
        );
      }
      final latest = state.value;
      if (latest == null) return;
      var replacementIndex = 0;
      final merged = <ChatMessage>[];
      for (final message in latest.messages) {
        if (message.id.isEmpty && replacementIndex < saved.length) {
          // unsaved tersimpan terurut terlama→terbaru; latest terbaru→terlama.
          merged.add(saved[saved.length - 1 - replacementIndex]);
          replacementIndex++;
        } else {
          merged.add(message);
        }
      }
      state = AsyncData(latest.copyWith(messages: merged, historySyncFailed: false));
    } catch (_) {
      final latest = state.value;
      if (latest != null) {
        state = AsyncData(latest.copyWith(historySyncFailed: true));
      }
    }
  }

  /// Hapus seluruh riwayat chat milik pengguna (PRD §6.7). Melempar
  /// [ChatException] bila gagal - UI menampilkan snackbar.
  Future<void> clearHistory() async {
    await ChatUseCases.clearMessages(ref.read(chatRepositoryProvider));
    state = const AsyncData(ChatMessagesState());
  }

  Future<void> _persistExchange({
    required ChatMessage user,
    required ChatMessage reply,
  }) async {
    final repo = ref.read(chatRepositoryProvider);
    final childId = ref.read(selectedChildProvider).value?.id;
    final savedUser = await repo.addMessage(
      role: ChatRole.user,
      content: user.content,
      safetyFlag: ChatSafetyFlag.none,
      childId: childId,
    );
    final savedReply = await repo.addMessage(
      role: ChatRole.assistant,
      content: reply.content,
      safetyFlag: reply.safetyFlag,
      childId: childId,
    );
    final latest = state.value;
    if (latest == null) return;
    state = AsyncData(
      latest.copyWith(
        messages: [
          for (final message in latest.messages)
            if (identical(message, reply))
              savedReply
            else if (identical(message, user))
              savedUser
            else
              message,
        ],
      ),
    );
  }
}

final chatMessagesProvider =
    AsyncNotifierProvider<ChatNotifier, ChatMessagesState>(ChatNotifier.new);
