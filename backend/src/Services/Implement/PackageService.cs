using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Data;
using backend.src.Dtos.Package;
using backend.src.Exceptions;
using backend.src.Models;
using backend.src.Services.Interface;
using Microsoft.EntityFrameworkCore;

namespace backend.src.Services.Implement
{
    public class PackageService : IPackageService
    {
        private readonly ApplicationDbContext _context;

        public PackageService(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<Packages> CreatePackage(CreatePackageDto dto)
        {
            if (string.IsNullOrWhiteSpace(dto.Title))
            {
                throw new Result("Tên package không được để trống");
            }

            if (dto.Price <= 0)
            {
                throw new Result("Giá package phải lớn hơn 0");
            }

            var check = await _context.Packages.FirstOrDefaultAsync(a => a.Title == dto.Title);
            if (check != null)
            {
                throw new Result("Package đã tồn tại");
            }

            var previlages = await ResolvePrevilages(dto.PrevilageIds);

            var newPackage = new Packages
            {
                Title = dto.Title,
                Price = dto.Price,
                Previlages = previlages
            };

            await _context.Packages.AddAsync(newPackage);
            await _context.SaveChangesAsync();

            return newPackage;
        }

        public async Task<Packages> UpdatePackage(UpdatePackageDto dto, int id)
        {
            var package = await _context.Packages.FindAsync(id);
            if (package == null)
            {
                throw new Result("Package không tồn tại");
            }

            if (string.IsNullOrWhiteSpace(dto.Title))
            {
                throw new Result("Tên package không được để trống");
            }

            if (dto.Price <= 0)
            {
                throw new Result("Giá package phải lớn hơn 0");
            }

            var previlages = await ResolvePrevilages(dto.PrevilageIds);

            package.Title = dto.Title;
            package.Price = dto.Price;
            package.Previlages = previlages;

            await _context.SaveChangesAsync();

            return package;
        }

        public async Task<Packages> DeletePackage(int id) 
        {
            var package = await _context.Packages.FindAsync(id);
            if (package == null)
            {
                throw new Result("Package không tồn tại");
            }

            _context.Remove(package);
            await _context.SaveChangesAsync();

            return package;
        }

        public async Task<ReaderPackageDto> PurchasePackage(int packageId, int userId)
        {
            var reader = await _context.Readers
                .FirstOrDefaultAsync(r => r.UserId == userId);

            if (reader == null)
            {
                throw new Result("Reader không tồn tại");
            }

            var package = await _context.Packages
                .FirstOrDefaultAsync(p => p.Id == packageId);

            if (package == null)
            {
                throw new Result("Package không tồn tại");
            }

            var now = DateTime.UtcNow;

            var hasActivePackage = await _context.ReaderPackages
                .AnyAsync(rp => rp.ReaderId == reader.Id
                    && rp.PackageId == packageId
                    && (rp.ExpiredAt == null || rp.ExpiredAt > now));

            if (hasActivePackage)
            {
                throw new Result("Bạn đã mua package này và vẫn còn hiệu lực");
            }

            var purchase = new ReaderPackages
            {
                ReaderId = reader.Id,
                PackageId = packageId,
                PurchasedAt = now,
                ExpiredAt = null
            };

            await _context.ReaderPackages.AddAsync(purchase);
            reader.IsPremium = true;

            await _context.SaveChangesAsync();

            purchase.Package = package;
            return MapToReaderPackageDto(purchase);
        }

        private async Task<List<Previlages>> ResolvePrevilages(List<int> previlageIds)
        {
            var distinctIds = previlageIds.Distinct().ToList();
            List<Previlages> previlages = new();

            if (distinctIds.Count > 0)
            {
                previlages = await _context.Previlages
                    .Where(a => distinctIds.Contains(a.Id))
                    .ToListAsync();

                var missingPrevilageIds = distinctIds.Except(previlages.Select(a => a.Id)).ToList();
                if (missingPrevilageIds.Count > 0)
                {
                    throw new Result($"Đặc quyền không tồn tại: {string.Join(", ", missingPrevilageIds)}");
                }
            }

            return previlages;
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
                PurchasedAt = purchase.PurchasedAt,
                ExpiredAt = purchase.ExpiredAt
            };
        }
    }
}