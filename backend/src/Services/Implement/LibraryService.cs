using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Data;
using backend.src.Exceptions;
using backend.src.Models;
using backend.src.Services.Interface;
using Microsoft.AspNetCore.Http.Metadata;
using Microsoft.EntityFrameworkCore;

namespace backend.src.Services.Implement
{
    public class LibraryService : ILibraryService
    {
        private readonly ApplicationDbContext _context;
        private readonly IMinioStorageService _minio;

        public LibraryService(ApplicationDbContext context, IMinioStorageService minio)
        {
            _context = context;
            _minio = minio;
        }

        public async Task<List<Libraries>> GetMangaInLibrary(int userId)
        {
            var mangas = await _context.Libraries
                .Where(a => a.ReaderId == userId)
                .Include(a => a.Manga)
                .ToListAsync();

            foreach (var manga in mangas)
            {
                if (!string.IsNullOrEmpty(manga.Manga?.Thumbnail))
                {
                    manga.Manga.Thumbnail = _minio.GetImageUrl(manga.Manga.Thumbnail);
                }
            }

            return mangas;
        }

        public async Task<Libraries> AddMangaToLibrary(int mangaId, int userId)
        {
            var checkManga = await _context.Libraries
                .FirstOrDefaultAsync(a => a.ReaderId == userId && a.MangaId == mangaId);
            
            if (checkManga != null)
            {
                throw new Result("Manga đã thêm vào mục thư viện của bạn");
            }

            var addManga = new Libraries
            {
                ReaderId = userId,
                MangaId = mangaId
            };

            await _context.Libraries.AddAsync(addManga);
            await _context.SaveChangesAsync();

            return addManga;
        }

        public async Task<Libraries> DeleteMangaToLibrary(int mangaId, int userId) 
        {
            var deleteManga = await _context.Libraries
                .FirstOrDefaultAsync(a => a.ReaderId == userId && a.MangaId == mangaId);
            
            if (deleteManga == null)
            {
                throw new Result("Không tìm thấy manga trong thư viện");
            }

            _context.Remove(deleteManga);
            await _context.SaveChangesAsync();

            return deleteManga;
        }
    }
}