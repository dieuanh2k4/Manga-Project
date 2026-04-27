using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Data;
using backend.src.Dtos.Manga;
using backend.src.Exceptions;
using backend.src.Models;
using backend.src.Services.Implement;
using backend.src.Services.Interface;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace backend.src.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class MangaController : ApiControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IMangaService _mangaservice;

        public MangaController(ApplicationDbContext context, IMangaService mangaService, ILogger<MangaController> logger) : base(logger)
        {
            _context = context;
            _mangaservice = mangaService;
        }

        [AllowAnonymous]
        [HttpGet("get-all-manga")]
        public async Task<IActionResult> GetAllManga()
        {
            try
            {
                var mangas = await _mangaservice.GetAllManga();

                return Ok(mangas);
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [AllowAnonymous]
        [HttpGet("get-manga-by-id/{id}")]
        public async Task<IActionResult> GetMangaById(int id)
        {
            try
            {
                var manga = await _mangaservice.GetAllMangaById(id);

                return Ok(manga);
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [Authorize(Policy = "AdminOnly")]
        [HttpPost("create-manga")]
        public async Task<IActionResult> CreateManga([FromForm] CreateMangaDto dto, IFormFile? file)
        {
            try
            {
                var uploadStatus = file != null && file.Length > 0 ? "Đang xử lý" : null;

                if (file != null)
                {
                    var fileUrl = await _mangaservice.UploadImage(file);
                    dto.Thumbnail = fileUrl;
                }

                var newManga = await _mangaservice.CreateManga(dto);

                return Ok(new
                {
                    message = "Thêm Manga thành công",
                    uploadStatus,
                    data = newManga
                });
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [Authorize(Policy = "AdminOnly")]
        [HttpPut("update-manga/{id}")]
        public async Task<IActionResult> UpdateManga([FromForm] UpdateMangaDto dto, IFormFile? file, int id) 
        {
            try 
            {
                var uploadStatus = file != null && file.Length > 0 ? "Đang xử lý" : null;

                if (file != null) 
                {
                    var fileUrl = await _mangaservice.UploadImage(file);
                    dto.Thumbnail = fileUrl;
                }

                var updateManga = await _mangaservice.UpdateManga(dto, id);

                return Ok(new
                {
                    message = "Cập nhật Manga thành công",
                    uploadStatus,
                    data = updateManga
                });
            }
            catch (Exception ex) 
            {
                return ReturnException(ex);
            }
        }

        [Authorize(Policy = "AdminOnly")]
        [HttpDelete("delete-manga/{id}")]
        public async Task<IActionResult> DeleteManga(int id) 
        {
            try 
            {
                var deleteManga = await _mangaservice.DeleteManga(id);

                _context.Manga.Remove(deleteManga);
                await _context.SaveChangesAsync();

                return Ok(new
                {
                    message = "Cập nhật manga thành công",
                    data = deleteManga
                });
            }
            catch (Exception ex) 
            {
                return ReturnException(ex);
            }
        }

        [AllowAnonymous]
        [HttpPost("search")]
        public async Task<IActionResult> Search(string query)
        {
            try 
            {
                var searchManga = await _mangaservice.Search(query);

                if (!searchManga.Any())
                {
                    return Ok(new
                    {
                        message = "Không tìm thấy manga. Hãy thử với từ khóa khác",
                        data = searchManga
                    });
                } 
                else
                {
                    return Ok(new
                    {
                        message = "Danh sách manga theo yêu cầu",
                        data = searchManga
                    });
                }
            }
            catch (Exception ex) 
            {
                return ReturnException(ex);
            }
        }

        [AllowAnonymous]
        [HttpPost("sort-by-genre")]
        public async Task<IActionResult> SortByGenre(int genreId)
        {
            try 
            {
                var sortManga = await _mangaservice.SortByGenre(genreId);

                if (!sortManga.Any())
                {
                    return Ok(new
                    {
                        message = "Không tìm thấy manga.",
                        data = sortManga
                    });
                } 
                else
                {
                    return Ok(new
                    {
                        message = "Danh sách manga theo thể loại.",
                        data = sortManga
                    });
                }
            }
            catch (Exception ex) 
            {
                return ReturnException(ex);
            }
        }

        [AllowAnonymous]
        [HttpPost("manga-ongoing")]
        public async Task<IActionResult> MangaOngoing()
        {
            try 
            {
                var ongoingManga = await _mangaservice.MangaOngoing();

                if  (!ongoingManga.Any())
                {
                    return Ok(new
                    {
                        message = "Không tìm thấy manga.",
                        data = ongoingManga
                    });
                } 
                else
                {
                    return Ok(new
                    {
                        message = "Danh sách manga đang tiến hành.",
                        data = ongoingManga
                    });
                }
            }
            catch (Exception ex) 
            {
                return ReturnException(ex);
            }
        }

        [AllowAnonymous]
        [HttpPost("manga-completed")]
        public async Task<IActionResult> MangaComplete()
        {
            try 
            {
                var completedManga = await _mangaservice.MangaComplete();

                if  (!completedManga.Any())
                {
                    return Ok(new
                    {
                        message = "Không tìm thấy manga.",
                        data = completedManga
                    });
                } 
                else
                {
                    return Ok(new
                    {
                        message = "Danh sách manga đang tiến hành.",
                        data = completedManga
                    });
                }
            }
            catch (Exception ex) 
            {
                return ReturnException(ex);
            }
        }
    }
}