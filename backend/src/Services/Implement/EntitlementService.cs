using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Data;
using backend.src.Dtos.Package;
using backend.src.Exceptions;
using backend.src.Models;
using backend.src.Services.Entitlements;
using backend.src.Services.helper;
using backend.src.Services.Interface;
using Microsoft.EntityFrameworkCore;

namespace backend.src.Services.Implement
{
    public class EntitlementService : IEntitlementService
    {
        private readonly ApplicationDbContext _context;

        public EntitlementService(ApplicationDbContext context)
        {
            _context = context;
        }

        // lấy các quyền hiện tại của user, trả về ReaderEntitlementsDto 
        public async Task<ReaderEntitlementsDto> GetReaderEntitlements(int userId)
        {
            var user = await _context.Users
                .AsNoTracking()
                .Include(u => u.Readers)
                .FirstOrDefaultAsync(u => u.Id == userId);

            if (user == null)
            {
                throw new Result("Người dùng không tồn tại");
            }

            if (string.Equals(user.Role, "Admin", StringComparison.OrdinalIgnoreCase))
            {
                return new ReaderEntitlementsDto
                {
                    ReaderId = 0,
                    HasActivePackage = true,
                    CanReadPremium = true,
                    Features = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
                    {
                        [EntitlementFeatureKeys.ReadPremium] = "true"
                    }
                };
            }

            var reader = user.Readers;

            if (reader == null)
            {
                throw new Result("Reader không tồn tại");
            }

            var now = DateTime.UtcNow;

            // One-user-one-package model: only keep the latest active purchase.
            var activePurchase = await _context.ReaderPackages
                .AsNoTracking()
                .Where(rp => rp.ReaderId == reader.Id && (rp.ExpiredAt == null || rp.ExpiredAt > now))
                .Include(rp => rp.Package!)
                    .ThenInclude(p => p.Previlages)
                .OrderByDescending(rp => rp.PurchasedAt)
                .FirstOrDefaultAsync();

            var features = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            var activePackages = new List<ReaderPackageDto>();

            if (activePurchase?.Package != null)
            {
                var package = activePurchase.Package;
                var packageHasPremium = false;

                foreach (var previlage in package.Previlages)
                {
                    var feature = EntilmentHelper.ParseFeature(previlage.Content);
                    if (string.IsNullOrWhiteSpace(feature.Key))
                    {
                        continue;
                    }

                    EntilmentHelper.MergeFeature(features, feature.Key, feature.Value);

                    if (EntilmentHelper.IsReadPremiumFeature(feature.Key) && EntilmentHelper.IsTruthy(feature.Value))
                    {
                        packageHasPremium = true;
                    }
                }

                // Backward-compatible behavior: old packages without any explicit privilege still grant premium.
                if (!packageHasPremium && package.Previlages.Count == 0)
                {
                    EntilmentHelper.MergeFeature(features, EntitlementFeatureKeys.ReadPremium, "true");
                }

                activePackages.Add(MapToReaderPackageDto(activePurchase));
            }

            var canReadPremium = EntilmentHelper.HasReadPremium(features);

            // Preserve old premium readers that were created before purchase history existed.
            if (!canReadPremium && reader.IsPremium && activePurchase == null)
            {
                var hasAnyPurchase = await _context.ReaderPackages
                    .AsNoTracking()
                    .AnyAsync(rp => rp.ReaderId == reader.Id);

                if (!hasAnyPurchase)
                {
                    canReadPremium = true;
                    EntilmentHelper.MergeFeature(features, EntitlementFeatureKeys.ReadPremium, "true");
                }
            }

            return new ReaderEntitlementsDto
            {
                ReaderId = reader.Id,
                HasActivePackage = activePurchase != null,
                CanReadPremium = canReadPremium,
                PremiumAccessExpiredAt = canReadPremium ? activePurchase?.ExpiredAt : null,
                Features = features,
                ActivePackages = activePackages
            };
        }

        // khi cần hỏi nhanh user có một quyền cụ thể không
        public async Task<bool> HasPrivilege(int userId, string privilegeCode)
        {
            var entitlements = await GetReaderEntitlements(userId);
            var normalizedCode = EntilmentHelper.CanonicalizeFeatureKey(EntilmentHelper.NormalizeFeatureKey(privilegeCode));

            if (EntilmentHelper.IsReadPremiumFeature(normalizedCode))
            {
                return entitlements.CanReadPremium;
            }

            if (!entitlements.Features.TryGetValue(normalizedCode, out var value))
            {
                return false;
            }

            return EntilmentHelper.IsTruthy(value);
        }

        // hàm bảo vệ truy cập chapter
        public async Task EnsureCanReadChapter(int? userId, Chapters chapter)
        {
            if (!chapter.IsPremium)
            {
                return;
            }

            if (!userId.HasValue)
            {
                throw new UnauthorizedAccessException("[NEED_PREMIUM] Chương này chỉ dành cho tài khoản premium. Vui lòng đăng nhập và mua gói phù hợp.");
            }

            var entitlements = await GetReaderEntitlements(userId.Value);
            if (!entitlements.CanReadPremium)
            {
                throw new UnauthorizedAccessException("[NEED_PREMIUM] Gói hiện tại không có quyền đọc chương premium hoặc đã hết hạn.");
            }
        }

        private static ReaderPackageDto MapToReaderPackageDto(ReaderPackages purchase)
        {
            var package = purchase.Package;

            return new ReaderPackageDto
            {
                PurchaseId = purchase.Id,
                PackageId = purchase.PackageId,
                PackageTitle = package?.Title,
                PackagePrice = package?.Price ?? 0,
                PackageDurationDays = package?.DurationDays ?? 0,
                PurchasedAt = purchase.PurchasedAt,
                ExpiredAt = purchase.ExpiredAt,
                PackagePrevilages = package?.Previlages.Select(p => p.Content ?? string.Empty).Where(c => !string.IsNullOrWhiteSpace(c)).ToList()
                    ?? new List<string>()
            };
        }
    }
}
