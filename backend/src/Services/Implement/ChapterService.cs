using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Data;
using backend.src.Dtos.Chapter;
using backend.src.Exceptions;
using backend.src.Models;
using backend.src.Services.Interface;
using Microsoft.EntityFrameworkCore;

namespace backend.src.Services.Implement
{
    public class ChapterService : IChapterService
    {
        private readonly ApplicationDbContext _context;

        public ChapterService(ApplicationDbContext context, IMinioStorageService minio)
        {
            _context = context;
        }

        public async Task<List<Chapters>> GetAllChapter(int idManga)
        {
            var mangaExists = await _context.Manga.AnyAsync(m => m.Id == idManga);

            if (!mangaExists)
            {
                throw new Result("Manga không tồn tại");
            }

            var chapters = await _context.Chapters
                .Where(c => c.MangaId == idManga)
                .ToListAsync();

            return chapters;
        }

        public async Task<Chapters> CreateChapter(CreateChapterDto chapterDto, int idManga) 
        {
            var manga = await _context.Manga.FindAsync(idManga);
            if (manga == null)
            {
                throw new Result("Manga không tồn tại");
            }

            var chapter = new Chapters 
            {
                ChapterNumber = chapterDto.ChapterNumber,
                MangaId = idManga,
                Title = chapterDto.Title,
                IsPremium = chapterDto.IsPremium
            };

            await _context.Chapters.AddAsync(chapter);

            manga.TotalChapter += 1;
            await _context.SaveChangesAsync();

            return chapter;
        }

        public async Task<Chapters> UpdateChapter(UpdateChapterDto dto, int idManga) 
        {
            var Chapter = await _context.Chapters.FindAsync(idManga);

            if (Chapter == null) 
            {
                throw new Result("Không tìm thấy Manga");
            }

            Chapter.ChapterNumber = dto.ChapterNumber;
            Chapter.Title = dto.Title;
            Chapter.IsPremium = dto.IsPremium;
            Chapter.MangaId = dto.MangaId;

            await _context.SaveChangesAsync();

            return Chapter;
        }

        public async Task<Chapters> DeleteChapter(int idManga, int idChapter) 
        {
            var manga = await _context.Manga.FindAsync(idManga);
            if (manga == null)
            {
                throw new Result("Manga không tồn tại");
            }

            var checkManga = await _context.Chapters.FindAsync(idManga);
            if (checkManga == null) 
            {
                throw new Result("Không tìm thấy Manga");
            }

            var Chapter = await _context.Chapters.FindAsync(idChapter);
            if (Chapter == null) 
            {
                throw new Result("Không tìm thấy Chapter");
            }

            manga.TotalChapter -= 1;
            await _context.SaveChangesAsync();

            return Chapter;
        }
    } 
}