using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Data;
using backend.src.Exceptions;
using backend.src.Services.Interface;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace backend.src.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class LibraryController : ApiControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly ILibraryService _libraryservice;

        public LibraryController(ApplicationDbContext context, ILibraryService libraryService, ILogger<LibraryController> logger) : base(logger)
        {
            _context = context;
            _libraryservice = libraryService;
        }

        [Authorize(Policy = "ReaderOnly")]
        [HttpGet("get-manga-in-library")]
        public async Task<IActionResult> GetMangaInLibrary()
        {
            try
            {
                var userId = GetCurrentUserId();
                if (userId == null)
                {
                    throw new UnauthorizedAccessException("Cần đăng nhập để thêm manga vào thư viện");
                }

                var  Manga = await _libraryservice.GetMangaInLibrary(userId.Value);

                return Ok(new
                {
                    message = "Lấy manga thành công",
                    data = Manga
                });
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [Authorize(Policy = "ReaderOnly")]
        [HttpPost("add-manga-to-library")]
        public async Task<IActionResult> AddMangaToLibrary(int mangaId)
        {
            try
            {
                var userId = GetCurrentUserId();
                if (userId == null)
                {
                    throw new UnauthorizedAccessException("Cần đăng nhập để thêm manga vào thư viện");
                }

                var addManga = await _libraryservice.AddMangaToLibrary(mangaId, userId.Value);

                return Ok(new
                {
                    message = "Thêm manga thành công vào thư viện",
                    data = addManga
                });
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [Authorize(Policy = "ReaderOnly")]
        [HttpDelete("delete-manga-to-library")]
        public async Task<IActionResult> DeleteMangaToLibrary(int mangaId)
        {
            try
            {
                var userId = GetCurrentUserId();
                if (userId == null)
                {
                    throw new UnauthorizedAccessException("Cần đăng nhập để thêm manga vào thư viện");
                }

                var  deleteManga = await _libraryservice.DeleteMangaToLibrary(mangaId, userId.Value);

                return Ok(new
                {
                    message = "Xóa manga thành công",
                    data = deleteManga
                });
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }
    }
}