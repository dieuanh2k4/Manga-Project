import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import 'auth_page.dart';
import '../../../manga/presentation/pages/home_page.dart';
import '../../../manga/presentation/pages/search_page.dart';
import '../../../vip/domain/entities/package_plan_entity.dart';
import '../../../vip/domain/entities/reader_entitlements_entity.dart';
import '../../../vip/domain/repositories/vip_repository.dart';
import '../../../vip/domain/usecases/get_all_packages_usecase.dart';
import '../../../vip/domain/usecases/get_my_entitlements_usecase.dart';
import '../../../vip/domain/usecases/purchase_package_usecase.dart';
import '../../../vip/presentation/controllers/vip_controller.dart';

class MePage extends StatelessWidget {
  const MePage({super.key});

  String _formatCurrency(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    var count = 0;

    for (var i = digits.length - 1; i >= 0; i--) {
      buffer.write(digits[i]);
      count += 1;
      if (count == 3 && i != 0) {
        buffer.write('.');
        count = 0;
      }
    }

    return '${buffer.toString().split('').reversed.join()} VND';
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final profile = auth.profile;
    final token = auth.session?.token ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        title: const Text('Me'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2F2F2F),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: auth.isBusy ? null : auth.refreshProfile,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: profile == null
          ? Center(
              child: Text(
                auth.errorMessage ?? 'Khong tai duoc thong tin user',
                textAlign: TextAlign.center,
              ),
            )
          : ChangeNotifierProvider(
              key: ValueKey(token),
              create: (context) {
                final repository = context.read<VipRepository>();

                return VipController(
                  getAllPackagesUseCase: GetAllPackagesUseCase(repository),
                  getMyEntitlementsUseCase: GetMyEntitlementsUseCase(
                    repository,
                  ),
                  purchasePackageUseCase: PurchasePackageUseCase(repository),
                )..initialize(token: token);
              },
              child: Builder(
                builder: (context) {
                  final vip = context.watch<VipController>();

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: const Color(0xFFFF6B00),
                          backgroundImage:
                              (profile.avatar != null &&
                                  profile.avatar!.startsWith('http'))
                              ? NetworkImage(profile.avatar!)
                              : null,
                          child:
                              (profile.avatar == null ||
                                  !profile.avatar!.startsWith('http'))
                              ? Text(
                                  (profile.fullName ?? 'U').trim().isEmpty
                                      ? 'U'
                                      : (profile.fullName!
                                            .trim()
                                            .substring(0, 1)
                                            .toUpperCase()),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    color: Color(0xFF222222),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          profile.fullName ??
                              auth.session?.userName ??
                              'Reader',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: profile.isPremium
                                ? const Color(0xFFFFE3CC)
                                : const Color(0xFFE4E4E4),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            profile.isPremium ? 'Premium' : 'Standard',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: profile.isPremium
                                  ? const Color(0xFFB34B09)
                                  : const Color(0xFF555555),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _InfoCard(
                          rows: [
                            _InfoRow(
                              label: 'Username',
                              value: auth.session?.userName ?? '-',
                            ),
                            _InfoRow(
                              label: 'Email',
                              value: profile.email ?? '-',
                            ),
                            _InfoRow(
                              label: 'Phone',
                              value: profile.phone ?? '-',
                            ),
                            _InfoRow(
                              label: 'Gender',
                              value: profile.gender ?? '-',
                            ),
                            _InfoRow(
                              label: 'Birth',
                              value: profile.birth ?? '-',
                            ),
                            _InfoRow(
                              label: 'Address',
                              value: profile.address ?? '-',
                            ),
                            _InfoRow(
                              label: 'Role',
                              value: auth.session?.role ?? '-',
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _VipCard(
                          isLoading: vip.isLoading,
                          isRefreshing: vip.isRefreshingEntitlements,
                          packages: vip.packages,
                          entitlements: vip.entitlements,
                          errorMessage: vip.errorMessage,
                          formatCurrency: _formatCurrency,
                          formatDate: _formatDate,
                          isPackagePurchasing: (id) =>
                              vip.purchasingPackageId == id,
                          isPackageActive: vip.isPackageActive,
                          onRefresh: () async {
                            await vip.refreshEntitlements();
                          },
                          onBuy: (package) async {
                            final success = await vip.purchase(package.id);
                            if (!context.mounted) {
                              return;
                            }

                            if (success) {
                              await auth.refreshProfile();
                              if (!context.mounted) {
                                return;
                              }
                            }

                            final message = success
                                ? (vip.purchaseMessage ?? 'Mua goi thanh cong')
                                : (vip.errorMessage ?? 'Mua goi that bai');

                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(message)));
                          },
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await auth.logout();
                              if (!context.mounted) {
                                return;
                              }
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) => const AuthPage(),
                                ),
                                (route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B00),
                              foregroundColor: const Color(0xFF222222),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            icon: const Icon(Icons.logout),
                            label: const Text('Đăng xuất'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 3,
        selectedItemColor: const Color(0xFFE8742B),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          }
          if (index == 2) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const SearchPage()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            label: 'Library',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Me'),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<_InfoRow> rows;

  const _InfoCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: rows
            .map(
              (row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 92,
                      child: Text(
                        row.label,
                        style: const TextStyle(color: Color(0xFF616161)),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.value,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});
}

class _VipCard extends StatelessWidget {
  final bool isLoading;
  final bool isRefreshing;
  final List<PackagePlanEntity> packages;
  final ReaderEntitlementsEntity? entitlements;
  final String? errorMessage;
  final String Function(int value) formatCurrency;
  final String Function(DateTime value) formatDate;
  final bool Function(int packageId) isPackagePurchasing;
  final bool Function(int packageId) isPackageActive;
  final Future<void> Function() onRefresh;
  final Future<void> Function(PackagePlanEntity package) onBuy;

  const _VipCard({
    required this.isLoading,
    required this.isRefreshing,
    required this.packages,
    required this.entitlements,
    required this.errorMessage,
    required this.formatCurrency,
    required this.formatDate,
    required this.isPackagePurchasing,
    required this.isPackageActive,
    required this.onRefresh,
    required this.onBuy,
  });

  List<String> _friendlyPrivileges(List<String> rawPrivileges) {
    String parseOne(String raw) {
      final parts = raw.split('=');
      final key = parts.first.trim().toUpperCase();
      final value = parts.length > 1 ? parts.sublist(1).join('=').trim() : '';

      switch (key) {
        case 'READ_PREMIUM':
          return value.toLowerCase() == 'true'
              ? 'Đọc chapter Premium'
              : 'Không mở khoá chapter Premium';
        case 'NO_ADS':
          return value.toLowerCase() == 'true'
              ? 'Không quảng cáo'
              : 'Có quảng cáo';
        case 'OFFLINE_DOWNLOAD':
          return value.toLowerCase() == 'true'
              ? 'Tải offline'
              : 'Không tải offline';
        case 'DAILY_CHAPTER_LIMIT':
          return value.isEmpty
              ? 'Giới hạn chapter mỗi ngày'
              : '$value chapter/ngày';
        case 'EARLY_ACCESS_DAYS':
          return value.isEmpty ? 'Đọc sớm' : 'Đọc sớm $value ngày';
        case 'MAX_DEVICES':
          return value.isEmpty ? 'Đa thiết bị' : 'Tối đa $value thiết bị';
        default:
          final normalized = key
              .split('_')
              .where((e) => e.isNotEmpty)
              .map((e) => e[0] + e.substring(1).toLowerCase())
              .join(' ');

          if (value.isEmpty) {
            return normalized;
          }

          return '$normalized: $value';
      }
    }

    final result = rawPrivileges
        .where((e) => e.trim().isNotEmpty)
        .map(parseOne)
        .toSet()
        .toList();

    return result;
  }

  Widget _buildPrivilegeChips(List<String> privileges) {
    final visibleCount = privileges.length > 3 ? 3 : privileges.length;
    final visible = privileges.take(visibleCount).toList();
    final hiddenCount = privileges.length - visibleCount;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...visible.map(
          (item) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE3CC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              item,
              style: const TextStyle(
                color: Color(0xFF8E4A1A),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        if (hiddenCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFEEDFD3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '+$hiddenCount quyền lợi khác',
              style: const TextStyle(
                color: Color(0xFF8E4A1A),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Gói VIP',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: isRefreshing ? null : onRefresh,
                icon: isRefreshing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
              ),
            ],
          ),
          if (entitlements != null) ...[
            const SizedBox(height: 4),
            Text(
              entitlements!.hasActivePackage
                  ? 'Trạng thái: Đang có gói hoạt động'
                  : 'Trạng thái: Chưa có gói hoạt động',
              style: const TextStyle(color: Color(0xFF555555)),
            ),
            if (entitlements!.premiumAccessExpiredAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Hết hạn: ${formatDate(entitlements!.premiumAccessExpiredAt!)}',
                  style: const TextStyle(color: Color(0xFFBA541E)),
                ),
              ),
          ],
          if (errorMessage != null && errorMessage!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                errorMessage!,
                style: const TextStyle(color: Color(0xFFBA541E)),
              ),
            ),
          const SizedBox(height: 10),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (packages.isEmpty)
            const Text(
              'Chưa có gói nào hiển thị',
              style: TextStyle(color: Color(0xFF666666)),
            )
          else
            Column(
              children: packages.map((package) {
                final friendlyPrivileges = _friendlyPrivileges(
                  package.privileges,
                );

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5ED),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFD8BF)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        package.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2F2F2F),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${formatCurrency(package.price)} • ${package.durationDays} ngày',
                        style: const TextStyle(color: Color(0xFF6A6A6A)),
                      ),
                      if (friendlyPrivileges.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _buildPrivilegeChips(friendlyPrivileges),
                        ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              (isPackageActive(package.id) ||
                                  isPackagePurchasing(package.id))
                              ? null
                              : () => onBuy(package),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE8742B),
                            foregroundColor: const Color(0xFF222222),
                          ),
                          child: isPackagePurchasing(package.id)
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  isPackageActive(package.id)
                                      ? 'Đang sử dụng'
                                      : 'Mua gói',
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
