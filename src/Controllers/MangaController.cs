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

                return Ok(newManga);
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

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

                return Ok(updateManga);
            }
            catch (Exception ex) 
            {
                return ReturnException(ex);
            }
        }

        [HttpDelete("delete-manga/{id}")]
        public async Task<IActionResult> DeleteManga(int id) 
        {
            try 
            {
                var deleteManga = await _mangaservice.DeleteManga(id);

                _context.Manga.Remove(deleteManga);
                await _context.SaveChangesAsync();

                throw new Result("Xóa manga thành công");
            }
            catch (Exception ex) 
            {
                return ReturnException(ex);
            }
        }
    }
}