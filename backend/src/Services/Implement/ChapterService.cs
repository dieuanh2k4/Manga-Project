using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Data;
using backend.src.Dtos.Chapter;
using backend.src.Exceptions;
using backend.src.Hubs;
using backend.src.Models;
using backend.src.Services.Interface;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;

namespace backend.src.Services.Implement
{
    public class ChapterService : IChapterService
    {
        private readonly ApplicationDbContext _context;
        private readonly IHubContext<NotificationHub> _hubContext;
        private readonly ILogger<ChapterService> _logger;

        public ChapterService(ApplicationDbContext context, IHubContext<NotificationHub> hubContext, ILogger<ChapterService> logger)
        {
            _context = context;
            _hubContext = hubContext;
            _logger = logger;
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

            var notification = new Notifications
            {
                Title = $"CHAPTER MỚI CỦA MANGA {manga.Title}",
                Content = $"Manga {manga.Title} vừa ra chapter {chapter.Title}",
                TargetRole = "user_interested_manga",
                MangaId = manga.Id,
                CreatedAt = DateTime.UtcNow,
                IsRead = false
            };

            await _context.Set<Notifications>().AddAsync(notification);
            await _context.SaveChangesAsync();

            // lấy danh sách các reader lưu manga vào library
            var targetUserIds = await _context.Libraries
                .Where(l => l.MangaId == manga.Id)
                .Join(
                    _context.Readers,
                    library => library.ReaderId,
                    reader => reader.Id,
                    (library, reader) => reader.UserId)
                .Distinct() // loại bỏ trùng lặp, đảm bảo mỗi userId chỉ xuất hiện 1 lần để gửi noti
                .ToListAsync();

            var targetUserGroups = targetUserIds
                .Select(NotificationHub.UserGroupName)
                .ToList();

            if (targetUserGroups.Count > 0)
            {
                try
                {
                    await _hubContext.Clients.Groups(targetUserGroups).SendAsync("ReceiveNotification", new
                    {
                        notification.Id,
                        notification.Title,
                        notification.TargetRole,
                        notification.Content,
                        notification.MangaId,
                        notification.CreatedAt
                    });
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Gui noti chapter moi that bai cho mangaId={MangaId}", manga.Id);
                }
            }

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