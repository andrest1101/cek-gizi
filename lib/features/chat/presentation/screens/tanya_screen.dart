import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/core/time/chat_dates.dart';
import 'package:cekgizi/features/chat/domain/entities/chat_message.dart';
import 'package:cekgizi/features/chat/presentation/providers/chat_providers.dart';
import 'package:cekgizi/features/chat/presentation/widgets/chat_composer.dart';
import 'package:cekgizi/features/chat/presentation/widgets/chat_day_divider.dart';
import 'package:cekgizi/features/chat/presentation/widgets/chat_empty_state.dart';
import 'package:cekgizi/features/chat/presentation/widgets/chat_followups.dart';
import 'package:cekgizi/features/chat/presentation/widgets/chat_header.dart';
import 'package:cekgizi/features/chat/presentation/widgets/chat_message_tile.dart';
import 'package:cekgizi/features/chat/presentation/widgets/chat_notice.dart';
import 'package:cekgizi/features/chat/presentation/widgets/safety_card.dart';
import 'package:cekgizi/features/chat/presentation/widgets/typing_indicator.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/shared/widgets/empty_state.dart';
import 'package:cekgizi/shared/widgets/error_card.dart';
import 'package:cekgizi/shared/widgets/skeleton.dart';

/// Tanya Gizi (PRD §6.7): ruang konsultasi edukasi dengan batas aman tegas.
///
/// Tidak ada logika bisnis di widget: pengiriman, optimistic UI, kuota, dan
/// sinkronisasi riwayat dikelola [ChatNotifier]. Penegakan keamanan (red
/// flag, kuota) ada di Edge Function `ask-nutrition`.
///
/// Tata letak v3.1: header ringkas → percakapan editorial → disclaimer tetap
/// → kotak tulis dengan konteks anak dan sisa kuota.
class TanyaScreen extends ConsumerStatefulWidget {
  const TanyaScreen({super.key});

  @override
  ConsumerState<TanyaScreen> createState() => _TanyaScreenState();
}

class _TanyaScreenState extends ConsumerState<TanyaScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  bool _canSend = false;
  bool _showJumpToLatest = false;

  /// Jarak gulir (dari bawah) yang dianggap "pengguna sedang membaca ke atas".
  static const double _jumpThreshold = 240;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncCanSend);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_syncCanSend)
      ..dispose();
    _focusNode.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _syncCanSend() {
    final can = _controller.text.trim().isNotEmpty;
    if (can != _canSend) setState(() => _canSend = can);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final show = _scrollController.offset > _jumpThreshold;
    if (show != _showJumpToLatest) {
      setState(() => _showJumpToLatest = show);
    }
  }

  void _send([String? preset]) {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty) return;
    if (preset == null) _controller.clear();
    ref.read(chatMessagesProvider.notifier).sendQuestion(text);
    _focusNode.unfocus();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _confirmClear() async {
    final colors = AppTheme.colorsOf(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.tanyaDeleteConfirmTitle),
        content: const Text(AppStrings.tanyaDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.tanyaDeleteCancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: colors.statusAlert),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(AppStrings.tanyaDeleteConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(chatMessagesProvider.notifier).clearHistory();
      if (!mounted) return;
      _showSnack(AppStrings.tanyaDeleteDone);
    } catch (_) {
      if (!mounted) return;
      _showSnack(AppStrings.tanyaDeleteError);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final chatAsync = ref.watch(chatMessagesProvider);
    final child = ref.watch(selectedChildProvider).value;
    final quotaAsync = ref.watch(remainingChatQuotaProvider);
    final quotaText = quotaAsync.maybeWhen(
      data: (value) =>
          value == null ? null : AppStrings.tanyaQuotaRemaining(value),
      orElse: () => null,
    );

    // Gulir otomatis hanya bila pengguna sedang dekat dasar percakapan.
    ref.listen(chatMessagesProvider, (previous, next) {
      final previousCount = previous?.value?.messages.length ?? 0;
      final nextCount = next.value?.messages.length ?? 0;
      if (nextCount <= previousCount) return;
      final offset = _scrollController.hasClients
          ? _scrollController.offset
          : 0.0;
      if (offset < 120) _scrollToBottom();
    });

    final hasMessages = chatAsync.value?.messages.isNotEmpty ?? false;
    final sending = chatAsync.value?.sending ?? false;
    final childLabel = child == null
        ? null
        : AppStrings.tanyaComposerContext(
            child.nickname,
            child.ageLabel(DateTime.now()),
          );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                ChatHeader(
                  onClose: () => context.pop(),
                  onClearHistory: _confirmClear,
                  canClear: hasMessages,
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: child == null
                            ? _NoChildBody(
                                onAddChild: () => context.push('/children/add'),
                              )
                            : chatAsync.when(
                                loading: _ChatSkeleton.new,
                                error: (error, stackTrace) => Center(
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(
                                      AppSpacing.xl,
                                    ),
                                    child: ErrorCard(
                                      message: AppStrings.tanyaError('offline'),
                                      onRetry: () =>
                                          ref.invalidate(chatMessagesProvider),
                                    ),
                                  ),
                                ),
                                data: (state) => _ChatBody(
                                  state: state,
                                  onSend: _send,
                                  scrollController: _scrollController,
                                ),
                              ),
                      ),
                      if (child != null && _showJumpToLatest)
                        Positioned(
                          right: AppSpacing.screenPadding,
                          bottom: AppSpacing.md,
                          child: _JumpToLatest(onPressed: _scrollToBottom),
                        ),
                    ],
                  ),
                ),
                if (child != null &&
                    (chatAsync.value?.historySyncFailed ?? false))
                  ChatSyncNotice(
                    onRetry: () =>
                        ref.read(chatMessagesProvider.notifier).retrySync(),
                  ),
                const ChatDisclaimer(),
                if (child != null)
                  ChatComposer(
                    controller: _controller,
                    focusNode: _focusNode,
                    canSend: _canSend && !sending,
                    onSend: () => _send(),
                    childLabel: childLabel,
                    quotaText: quotaText,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoChildBody extends StatelessWidget {
  const _NoChildBody({required this.onAddChild});

  final VoidCallback onAddChild;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: EmptyState(
          icon: Icons.child_care_rounded,
          title: AppStrings.tanyaNoChildTitle,
          body: AppStrings.tanyaNoChildBody,
          action: FilledButton(
            onPressed: onAddChild,
            child: const Text(AppStrings.tanyaNoChildCta),
          ),
        ),
      ),
    );
  }
}

class _ChatSkeleton extends StatelessWidget {
  const _ChatSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: const [
        Skeleton(width: 90, height: 12, radius: 6),
        SizedBox(height: AppSpacing.lg),
        Skeleton(width: 250, height: 16),
        SizedBox(height: AppSpacing.sm),
        Skeleton(width: 210, height: 16),
        SizedBox(height: AppSpacing.xxl),
        Align(
          alignment: Alignment.centerRight,
          child: Skeleton(width: 180, height: 48, radius: 18),
        ),
        SizedBox(height: AppSpacing.xxl),
        Skeleton(width: 240, height: 16),
        SizedBox(height: AppSpacing.sm),
        Skeleton(width: 190, height: 16),
      ],
    );
  }
}

class _ChatBody extends ConsumerWidget {
  const _ChatBody({
    required this.state,
    required this.onSend,
    required this.scrollController,
  });

  final ChatMessagesState state;
  final void Function(String question) onSend;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEmpty =
        state.messages.isEmpty && !state.sending && state.sendError == null;

    if (isEmpty) return ChatEmptyState(onAsk: onSend);

    final now = DateTime.now();
    // State menyimpan pesan terbaru lebih dulu; bangun kronologis agar
    // pembatas hari dan pengelompokan pesan konsisten.
    final chronological = state.messages.reversed.toList();
    final items = <Widget>[];

    for (var index = 0; index < chronological.length; index++) {
      final message = chronological[index];
      final previous = index > 0 ? chronological[index - 1] : null;
      final next = index + 1 < chronological.length
          ? chronological[index + 1]
          : null;

      final startsNewDay =
          previous == null ||
          !isSameChatDay(previous.createdAt, message.createdAt);
      if (startsNewDay) {
        items.add(ChatDayDivider(at: message.createdAt, now: now));
      }

      if (message.role == ChatRole.assistant &&
          message.safetyFlag != ChatSafetyFlag.none) {
        items.add(
          SafetyCard(
            key: ValueKey('safety-${message.createdAt.microsecondsSinceEpoch}'),
            flag: message.safetyFlag,
          ),
        );
      }

      final groupedWithPrevious =
          previous != null &&
          previous.role == message.role &&
          !startsNewDay &&
          message.createdAt.difference(previous.createdAt).inMinutes.abs() <= 5;
      final groupedWithNext =
          next != null &&
          next.role == message.role &&
          isSameChatDay(next.createdAt, message.createdAt) &&
          next.createdAt.difference(message.createdAt).inMinutes.abs() <= 5;

      items.add(
        Padding(
          padding: EdgeInsets.only(
            top: groupedWithPrevious ? AppSpacing.sm : AppSpacing.lg,
          ),
          child: ChatMessageTile(message: message, showTime: !groupedWithNext),
        ),
      );
    }

    final newest = state.messages.isEmpty ? null : state.messages.first;
    if (!state.sending &&
        newest != null &&
        state.followups.isNotEmpty &&
        newest.role == ChatRole.assistant) {
      items.add(ChatFollowups(followups: state.followups, onSend: onSend));
    }

    if (state.sendError != null) {
      items.add(
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: ChatInlineError(
            message: AppStrings.tanyaError(state.sendError!),
            onRetry: () => ref.read(chatMessagesProvider.notifier).retrySend(),
          ),
        ),
      );
    } else if (state.sending) {
      items.add(
        const Padding(
          padding: EdgeInsets.only(top: AppSpacing.lg),
          child: TypingIndicator(),
        ),
      );
    }

    final reversed = items.reversed.toList(growable: false);
    return ListView.builder(
      controller: scrollController,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        AppSpacing.md,
      ),
      itemCount: reversed.length,
      itemBuilder: (context, index) => reversed[index],
    );
  }
}

class _JumpToLatest extends StatelessWidget {
  const _JumpToLatest({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: colors.outline, width: 1),
      ),
      child: IconButton(
        tooltip: AppStrings.tanyaScrollToLatest,
        onPressed: onPressed,
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: colors.textSecondary,
        ),
      ),
    );
  }
}
