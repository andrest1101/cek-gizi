import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/chat/domain/entities/chat_message.dart';
import 'package:cekgizi/features/chat/presentation/providers/chat_providers.dart';
import 'package:cekgizi/features/chat/presentation/widgets/chat_bubble.dart';
import 'package:cekgizi/features/chat/presentation/widgets/safety_card.dart';
import 'package:cekgizi/features/chat/presentation/widgets/typing_indicator.dart';
import 'package:cekgizi/shared/illustrations/chat_illustration.dart';
import 'package:cekgizi/shared/widgets/empty_state.dart';
import 'package:cekgizi/shared/widgets/error_card.dart';
import 'package:cekgizi/shared/widgets/screen_header.dart';
import 'package:cekgizi/shared/widgets/skeleton.dart';

/// Tanya Gizi (PRD §6.7): chat edukasi umum dengan batas aman tegas.
///
/// Tidak ada logika bisnis di widget: pengiriman, optimistic UI, kuota,
/// dan sinkronisasi riwayat dikelola [ChatNotifier]. Penegakan keamanan
/// (red flag, kuota) ada di Edge Function `ask-nutrition`.
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

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncCanSend);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_syncCanSend)
      ..dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _syncCanSend() {
    final can = _controller.text.trim().isNotEmpty;
    if (can != _canSend) setState(() => _canSend = can);
  }

  void _send([String? preset]) {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty) return;
    if (preset == null) _controller.clear();
    ref.read(chatMessagesProvider.notifier).sendQuestion(text);
    _focusNode.unfocus();
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
    final colors = AppTheme.colorsOf(context);
    final chatAsync = ref.watch(chatMessagesProvider);
    final child = ref.watch(selectedChildProvider).value;
    final quotaAsync = ref.watch(remainingChatQuotaProvider);
    final quotaText = quotaAsync.maybeWhen(
      data: (value) =>
          value == null ? null : AppStrings.tanyaQuotaRemaining(value),
      orElse: () => null,
    );

    // Gulir ke bawah saat jumlah pesan bertambah.
    ref.listen(chatMessagesProvider, (previous, next) {
      final previousCount = previous?.value?.messages.length ?? 0;
      final nextCount = next.value?.messages.length ?? 0;
      if (nextCount > previousCount) _scrollToBottom();
    });

    final hasMessages = chatAsync.value?.messages.isNotEmpty ?? false;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.md,
                AppSpacing.screenPadding,
                0,
              ),
              child: ScreenHeader(
                eyebrow: AppStrings.tanyaEyebrow,
                title: AppStrings.tanyaTitle,
                trailing: hasMessages
                    ? IconButton(
                        tooltip: AppStrings.tanyaDeleteHistory,
                        onPressed: _confirmClear,
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: colors.textSecondary,
                        ),
                        // Semantics: tooltip jadi label otomatis.
                      )
                    : null,
              ),
            ),
            _DisclaimerBanner(),
            if (quotaText != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  0,
                  AppSpacing.screenPadding,
                  AppSpacing.xs,
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Semantics(
                    label: '${AppStrings.tanyaQuotaSemantics}: $quotaText',
                    child: Text(
                      quotaText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label.copyWith(
                        color: colors.textSecondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: child == null
                  ? _NoChildBody(
                      onAddChild: () => context.push('/children/add'),
                    )
                  : chatAsync.when(
                      loading: _ChatSkeleton.new,
                      error: (error, stackTrace) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: ErrorCard(
                            message: AppStrings.tanyaError('offline'),
                            onRetry: () => ref.invalidate(chatMessagesProvider),
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
            if (child != null) ...[
              if (chatAsync.value?.historySyncFailed ?? false)
                _SyncFailedBanner(
                  onRetry: () =>
                      ref.read(chatMessagesProvider.notifier).retrySync(),
                ),
              _InputBar(
                controller: _controller,
                focusNode: _focusNode,
                canSend: _canSend && !(chatAsync.value?.sending ?? false),
                onSend: () => _send(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Banner tetap (PRD §6.7): selalu terlihat, tidak bisa ditutup.
class _DisclaimerBanner extends StatelessWidget {
  const _DisclaimerBanner();

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        AppSpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: colors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                AppStrings.tanyaDisclaimerBanner,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
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
        Align(
          alignment: Alignment.centerRight,
          child: Skeleton(width: 220, height: 52, radius: 16),
        ),
        SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerLeft,
          child: Skeleton(width: 260, height: 84, radius: 16),
        ),
        SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerRight,
          child: Skeleton(width: 180, height: 52, radius: 16),
        ),
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

    if (isEmpty) {
      return ListView(
        key: const Key('tanya-empty-list'),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.xl,
        ),
        children: [
          const SizedBox(height: AppSpacing.lg),
          EmptyState(
            icon: Icons.chat_bubble_outline_rounded,
            illustration: const ChatIllustration(size: 112),
            title: AppStrings.tanyaEmptyTitle,
            body: AppStrings.tanyaEmptyBody,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            AppStrings.tanyaQuickChipsTitle,
            style: AppTextStyles.label.copyWith(
              color: AppTheme.colorsOf(context).textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: const [
              _QuickChip(label: AppStrings.tanyaChipMpasi),
              _QuickChip(label: AppStrings.tanyaChipPickyEater),
              _QuickChip(label: AppStrings.tanyaChipSnack),
              _QuickChip(label: AppStrings.tanyaChipMilk),
            ],
          ),
        ],
      );
    }

    // Item terbalik: index 0 = paling bawah (dekat input).
    final items = <Widget>[];
    if (state.sendError != null) {
      items.add(
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: ErrorCard(
            message: AppStrings.tanyaError(state.sendError!),
            onRetry: () => ref.read(chatMessagesProvider.notifier).retrySend(),
          ),
        ),
      );
    } else if (state.sending) {
      items.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: TypingIndicator(),
        ),
      );
    }

    for (var index = 0; index < state.messages.length; index++) {
      final message = state.messages[index];
      final isAssistant = message.role == ChatRole.assistant;
      final isNewest = index == 0;

      if (isAssistant &&
          isNewest &&
          !state.sending &&
          state.followups.isNotEmpty) {
        items.add(_FollowupsRow(followups: state.followups, onSend: onSend));
      }
      if (isAssistant && message.safetyFlag != ChatSafetyFlag.none) {
        items.add(SafetyCard(flag: message.safetyFlag));
      }
      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: ChatBubble(message: message),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.md,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => items[index],
    );
  }
}

class _QuickChip extends ConsumerWidget {
  const _QuickChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colorsOf(context);
    return ActionChip(
      label: Text(label),
      onPressed: () =>
          ref.read(chatMessagesProvider.notifier).sendQuestion(label),
      labelStyle: AppTextStyles.label.copyWith(color: colors.textPrimary),
      backgroundColor: colors.surfaceVariant,
      side: BorderSide(color: colors.outline, width: 1),
      shape: const StadiumBorder(),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}

class _FollowupsRow extends StatelessWidget {
  const _FollowupsRow({required this.followups, required this.onSend});

  final List<String> followups;
  final void Function(String question) onSend;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.tanyaFollowupsTitle,
            style: AppTextStyles.label.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final followup in followups)
                ActionChip(
                  label: Text(followup),
                  onPressed: () => onSend(followup),
                  labelStyle: AppTextStyles.label.copyWith(
                    color: colors.textPrimary,
                  ),
                  backgroundColor: colors.surfaceVariant,
                  side: BorderSide(color: colors.outline, width: 1),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SyncFailedBanner extends StatelessWidget {
  const _SyncFailedBanner({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.xs,
        AppSpacing.screenPadding,
        0,
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 18,
            color: colors.statusWatchText,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              AppStrings.tanyaSyncFailed,
              style: AppTextStyles.label.copyWith(color: colors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text(AppStrings.tanyaSyncRetry),
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.canSend,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool canSend;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outline, width: 1)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.sm,
          AppSpacing.screenPadding,
          AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Semantics(
                label: AppStrings.tanyaInputSemantics,
                textField: true,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  minLines: 1,
                  maxLines: 4,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.send,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => canSend ? onSend() : null,
                  decoration: const InputDecoration(
                    hintText: AppStrings.tanyaInputHint,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filled(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: canSend ? onSend : null,
              tooltip: AppStrings.tanyaSendSemantics,
              icon: const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
