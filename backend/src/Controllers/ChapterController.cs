using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Data;
using backend.src.Dtos.Chapter;
using backend.src.Exceptions;
using backend.src.Models;
using backend.src.Services.Interface;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;


namespace backend.src.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ChapterController : ApiControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IChapterService _chapter;
        
        public ChapterController(ApplicationDbContext context, IChapterService chapter, ILogger<ChapterController> logger) : base(logger)
        {
            _context = context;
            _chapter = chapter;
        }

        [AllowAnonymous]
        [HttpGet("get-all-chapter/{idManga}")]
        public async Task<IActionResult> GetAllChapter(int idManga)
        {
            try
            {
                var chapters = await _chapter.GetAllChapter(idManga);

                return Ok(chapters);
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [Authorize(Policy = "AdminOnly")]
        [HttpPost("create-chapter/{idManga}")]
        public async Task<IActionResult> CreateChapter([FromForm] CreateChapterDto dto, int idManga)
        {
            try
            {
                var chapter = await _chapter.CreateChapter(dto, idManga);

                return Ok(new
                {
                    message = "Thêm Chapter thành công",
                    data = chapter
                });
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [Authorize(Policy = "AdminOnly")] 
        [HttpPut("update-chapter/{idManga}")]
        public async Task<IActionResult> UpdateChapter([FromForm] UpdateChapterDto dto, int idManga)
        {
            try
            {
                var chapter = await _chapter.UpdateChapter(dto, idManga);

                return Ok(new
                {
                    message = "Cập nhật Chapter thành công",
                    data = chapter
                });
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [Authorize(Policy = "AdminOnly")] 
        [HttpPut("delete-chapter/{idManga}")]
        public async Task<IActionResult> DeleteChapter(int idManga, int idChapter)
        {
            try
            {
                var chapter = await _chapter.DeleteChapter(idManga, idChapter);

                _context.Chapters.Remove(chapter);
                await _context.SaveChangesAsync();

                return Ok(new
                {
                    message = "Xóa chapter thành công",
                    data = chapter
                });
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }
    }
}