using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Data;
using backend.src.Exceptions;
using backend.src.Models;
using backend.src.Services.Interface;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;

namespace backend.src.Services.Implement
{
    public class PageService : IPageService
    {
        private readonly ApplicationDbContext _context;
        private readonly IMinioStorageService _minio;

        public PageService(ApplicationDbContext context, IMinioStorageService minio)
        {
            _context = context;
            _minio = minio;
        }

        public async Task<List<Pages>> GetAllPage(int idManga, int idChapter)
        {
            var pages = await _context.Pages
                .Where(p => p.ChapterId == idChapter && p.MangaId == idManga)
                .ToListAsync();

            if (!pages.Any())
            {
                throw new Result("Không có page nào");
            }

            return pages;
        }

        public async Task<List<Pages>> AddPageToChapter(int idManga, int idChapter, List<IFormFile> files)
        {
            if (files == null || files.Count == 0)
            {
                throw new Result("Vui lòng chọn ít nhất 1 ảnh");
            }

            var manga = await _context.Manga.FindAsync(idManga);
            if (manga == null)
            {
                throw new Result("Manga không tồn tại");
            }

            var chapter = await _context.Chapters
                .FirstOrDefaultAsync(c => c.Id == idChapter && c.MangaId == idManga);

            if (chapter == null)
            {
                throw new Result("Chapter không tồn tại hoặc không thuộc manga này");
            }

            var newPages = new List<Pages>();
            var folder = $"{manga.Title}/{chapter.ChapterNumber}";

            for (var i = 0; i < files.Count; i++)
            {
                var file = files[i];
                if (file == null || file.Length == 0)
                {
                    continue;
                }

                var imagePath = await _minio.UploadImageAsync(file, folder);

                newPages.Add(new Pages
                {
                    MangaId = idManga,
                    ChapterId = idChapter,
                    ImageUrl = imagePath
                });
            }

            if (newPages.Count == 0)
            {
                throw new Result("Không có file ảnh hợp lệ để upload");
            }

            await _context.Pages.AddRangeAsync(newPages);
            await _context.SaveChangesAsync();

            return newPages;
        }
    }
}
