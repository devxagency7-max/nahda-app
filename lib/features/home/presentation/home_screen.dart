import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../case_details/presentation/case_details_screen.dart';
import '../../case_list/presentation/case_list_filter.dart';
import '../../case_list/presentation/case_list_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../returned_cases/presentation/returned_cases_screen.dart';
import '../domain/home_summary.dart';
import 'home_providers.dart';
import 'widgets/home_counters_row.dart';
import 'widgets/home_drawer.dart';
import 'widgets/home_header.dart';
import 'widgets/home_search_bar.dart';
import 'widgets/sync_banner_bar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(homeDataProvider);

    return AppBackground(
      child: homeAsync.when(
        loading: () => const Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: _ErrorState(onRetry: () => ref.invalidate(homeDataProvider)),
          ),
        ),
        // زرّ "حالة جديدة": أُعيد بعد أن مُنحت `social_worker` صلاحية
        // `create_case` (§7.1، `BACKEND_CHANGE_RESPONSE_3.md`، 2026-09-19).
        // يفتح `CaseDetailsScreen` في وضع الإنشاء (`caseId: null`) — نفس
        // شاشة تفاصيل الحالة بالضبط، لكن كل الأقسام تُجمَع محليًا وتُرسَل في
        // طلب واحد فقط عند الضغط على "إنشاء الحالة" في آخر تاب (§20 + طلب
        // 15، `BACKEND_CHANGE_REQUEST_7.md`).
        // **قيد معروف:** الحالة الناتجة تُنشأ `unassigned` — الإسناد التلقائي
        // للمُنشئ لا يزال معلّقًا (`BACKEND_CHANGE_REQUEST_4.md`)؛ الشاشة
        // تعرض تنبيهًا صريحًا بهذا بعد نجاح الإنشاء.
        data: (data) => Scaffold(
          backgroundColor: Colors.transparent,
          drawer: HomeDrawer(data: data),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => CaseDetailsScreen.openForCreate(context),
            icon: const Icon(Icons.add),
            label: const Text('حالة جديدة'),
          ),
          body: SafeArea(
            child: Column(
              children: [
                const SyncBannerBar(),
                Expanded(child: _HomeContent(data: data)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  final HomeData data;

  const _HomeContent({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(homeDataProvider),
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  100, // مساحة تحت لزرار الـ FAB
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Top App Bar & Greeting below it
                    Builder(
                      builder: (scaffoldContext) {
                        return FadeSlideIn(
                          child: HomeHeader(
                            fallbackName: data.socialWorkerName,
                            unreadNotifications: data.unreadNotifications,
                            onNotificationsTap: () => NotificationsScreen.open(context),
                            onMenuTap: () {
                              Scaffold.of(scaffoldContext).openDrawer();
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // 2. The 3 Summary Cards in the Upper Section
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 40),
                      child: HomeCountersRow(
                        counters: data.counters,
                        onTapFilter: (filter) {
                          if (filter == CaseListFilter.returned) {
                            ReturnedCasesScreen.open(context, data);
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    CaseListScreen(data: data, initialFilter: filter),
                              ),
                            );
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // 3. Prominent Search Section with Title (Hero transition)
                    const FadeSlideIn(
                      delay: Duration(milliseconds: 80),
                      child: HomeSearchBar(),
                    ),

                    const Spacer(),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 40, color: AppColors.danger),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'تعذر تحميل البيانات',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'يبدو أن الاتصال بالإنترنت غير متاح. سيتم عرض آخر بيانات محفوظة عند توفرها.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
