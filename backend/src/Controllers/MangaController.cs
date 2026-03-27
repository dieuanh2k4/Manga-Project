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
                if (file != null)
                {
                    var fileUrl = await _mangaservice.UploadImage(file);
                    dto.Thumbnail = fileUrl;
                }

                var newManga = await _mangaservice.CreateManga(dto);

                return Ok(new
                {
                    message = "Thêm Manga thành công",
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
                if (file != null) 
                {
                    var fileUrl = await _mangaservice.UploadImage(file);
                    dto.Thumbnail = fileUrl;
                }

                var updateManga = await _mangaservice.UpdateManga(dto, id);

                return Ok(new
                {
                    message = "Cập nhật Manga thành công",
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
    }
}