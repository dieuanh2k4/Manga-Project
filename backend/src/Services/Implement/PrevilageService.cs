using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Xml;
using backend.src.Data;
using backend.src.Dtos.Previlage;
using backend.src.Exceptions;
using backend.src.Models;
using backend.src.Services.Interface;
using Microsoft.EntityFrameworkCore;

namespace backend.src.Services.Implement
{
    public class PrevilageService : IPrevilageService
    {
        private readonly ApplicationDbContext _context;

        public PrevilageService(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<Previlages> CreatePrevilage(CreatePrevilageDto dto)
        {
            var checkPrevilage = await _context.Previlages.FirstOrDefaultAsync(a => a.Content == dto.Content);
            if (checkPrevilage != null)
            {
                throw new Result("Đặc quyền đã tồn tại");
            }

            var newPrevilage = new Previlages
            {
                Content = dto.Content
            };

            await _context.AddAsync(newPrevilage);
            await _context.SaveChangesAsync();

            return newPrevilage;
        }

        public async Task<Previlages> UpdatePrevilage(UpdatePrevilageDto dto, int id)
        {
            var Previlage = await _context.Previlages.FindAsync(id);
            if (Previlage == null)
            {
                throw new Result("Đặc quyền không tồn tại");
            }

            Previlage.Content = dto.Content;
            
            await _context.SaveChangesAsync();

            return Previlage;
        }

        public async Task<Previlages> DeletePrevilage(int id)
        {
            var Previlage = await _context.Previlages.FindAsync(id);
            if (Previlage == null)
            {
                throw new Result("Đặc quyền không tồn tại");
            }
            
            _context.Remove(Previlage);
            await _context.SaveChangesAsync();

            return Previlage;
        }
    }
}