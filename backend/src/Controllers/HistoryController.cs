using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Data;
using backend.src.Dtos.History;
using backend.src.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace backend.src.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Policy = "ReaderOnly")]
    public class HistoryController : ApiControllerBase
    {
        private readonly ApplicationDbContext _context;

        public HistoryController(ApplicationDbContext context, ILogger<HistoryController> logger) : base(logger)
        {
            _context = context;
        }

        [HttpPost("upsert-history")]
        public async Task<IActionResult> UpsertHistory([FromBody] UpsertHistoryDto dto)
        {
            try
            {
                var userId = GetCurrentUserId();
                if (userId == null)
                {
                    throw new UnauthorizedAccessException("Token khong hop le");
                }

                var reader = await _context.Readers.FirstOrDefaultAsync(r => r.UserId == userId.Value);
                if (reader == null)
                {
                    throw new KeyNotFoundException("Khong tim thay reader");
                }

                if (dto.MangaId <= 0 || dto.ChapterId <= 0 || dto.PageNumber <= 0)
                {
                    throw new ArgumentException("Thong tin lich su khong hop le");
                }

                var mangaExists = await _context.Manga.AnyAsync(m => m.Id == dto.MangaId);
                if (!mangaExists)
                {
                    throw new KeyNotFoundException("Khong tim thay manga");
                }

                var chapterExists = await _context.Chapters.AnyAsync(c => c.Id == dto.ChapterId && c.MangaId == dto.MangaId);
                if (!chapterExists)
                {
                    throw new KeyNotFoundException("Khong tim thay chapter");
                }

                var pageExists = await _context.Pages.AnyAsync(p => p.Id == dto.PageNumber && p.ChapterId == dto.ChapterId && p.MangaId == dto.MangaId);
                if (!pageExists)
                {
                    throw new KeyNotFoundException("Khong tim thay page");
                }

                var history = await _context.History
                    .FirstOrDefaultAsync(h => h.ReaderId == reader.Id && h.MangaId == dto.MangaId);

                if (history == null)
                {
                    history = new History
                    {
                        ReaderId = reader.Id,
                        MangaId = dto.MangaId,
                        LastChapterId = dto.ChapterId,
                        LastPageId = dto.PageNumber,
                        IsCompleted = dto.IsCompleted ?? false,
                        UpdateAt = TimeOnly.FromDateTime(DateTime.UtcNow)
                    };

                    _context.History.Add(history);
                }
                else
                {
                    history.LastChapterId = dto.ChapterId;
                    history.LastPageId = dto.PageNumber;
                    history.IsCompleted = dto.IsCompleted ?? history.IsCompleted;
                    history.UpdateAt = TimeOnly.FromDateTime(DateTime.UtcNow);
                }

                await _context.SaveChangesAsync();

                return Ok(new
                {
                    message = "Cap nhat lich su doc thanh cong",
                    data = history
                });
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [HttpGet("get-history")]
        public async Task<IActionResult> GetHistory()
        {
            try
            {
                var userId = GetCurrentUserId();
                if (userId == null)
                {
                    throw new UnauthorizedAccessException("Token khong hop le");
                }

                var reader = await _context.Readers.FirstOrDefaultAsync(r => r.UserId == userId.Value);
                if (reader == null)
                {
                    throw new KeyNotFoundException("Khong tim thay reader");
                }

                var history = await _context.History
                    .Where(h => h.ReaderId == reader.Id)
                    .OrderByDescending(h => h.UpdateAt)
                    .Select(h => new HistoryItemDto
                    {
                        MangaId = h.MangaId,
                        LastChapterId = h.LastChapterId,
                        LastPageId = h.LastPageId,
                        IsCompleted = h.IsCompleted,
                        UpdateAt = h.UpdateAt,
                        MangaTitle = h.Manga != null ? h.Manga.Title : null,
                        MangaThumbnail = h.Manga != null ? h.Manga.Thumbnail : null
                    })
                    .ToListAsync();

                return Ok(new
                {
                    message = "Lay lich su doc thanh cong",
                    data = history
                });
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [HttpDelete("delete-history")]
        public async Task<IActionResult> DeleteHistory(int mangaId)
        {
            try
            {
                var userId = GetCurrentUserId();
                if (userId == null)
                {
                    throw new UnauthorizedAccessException("Token khong hop le");
                }

                var reader = await _context.Readers.FirstOrDefaultAsync(r => r.UserId == userId.Value);
                if (reader == null)
                {
                    throw new KeyNotFoundException("Khong tim thay reader");
                }

                var history = await _context.History
                    .FirstOrDefaultAsync(h => h.ReaderId == reader.Id && h.MangaId == mangaId);

                if (history == null)
                {
                    throw new KeyNotFoundException("Khong tim thay lich su doc");
                }

                _context.History.Remove(history);
                await _context.SaveChangesAsync();

                return Ok(new
                {
                    message = "Xoa lich su doc thanh cong",
                    data = history
                });
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }
    }
}
