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

            var check = await _context.Packages.FirstOrDefaultAsync(a => a.Title == dto.Title);
            if (check != null)
            {
                throw new Result("Package đã tồn tại");
            }

            var previlageIds = dto.PrevilageIds.Distinct().ToList();
            List<Previlages> previlages = new();

            if (previlageIds.Count > 0)
            {
                previlages = await _context.Previlages
                    .Where(a => previlageIds.Contains(a.Id))
                    .ToListAsync();

                var missingPrevilageIds = previlageIds.Except(previlages.Select(a => a.Id)).ToList();
                if (missingPrevilageIds.Count > 0)
                {
                    throw new Result($"Đặc quyền không tồn tại: {string.Join(", ", missingPrevilageIds)}");
                }
            }

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

            var previlageIds = dto.PrevilageIds.Distinct().ToList();
            List<Previlages> previlages = new();

            if (previlageIds.Count > 0)
            {
                previlages = await _context.Previlages
                    .Where(a => previlageIds.Contains(a.Id))
                    .ToListAsync();

                var missingPrevilageIds = previlageIds.Except(previlages.Select(a => a.Id)).ToList();
                if (missingPrevilageIds.Count > 0)
                {
                    throw new Result($"Đặc quyền không tồn tại: {string.Join(", ", missingPrevilageIds)}");
                }
            }

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
    }
}