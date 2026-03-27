using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Data;
using backend.src.Dtos.Genre;
using backend.src.Exceptions;
using backend.src.Services.Interface;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace backend.src.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class GenreController : ApiControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IGenreService _genre;

        public GenreController(ApplicationDbContext context, IGenreService genre, ILogger<GenreController> logger) : base(logger)
        {
            _context = context;
            _genre = genre;
        }

        [AllowAnonymous]
        [HttpGet("get-all-genre")]
        public async Task<IActionResult> GetAllGenre()
        {
            try
            {
                var genres = await _genre.GetAllGenre();

                return Ok(genres);
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [Authorize(Policy = "AdminOnly")]
        [HttpPost("create-genre")]
        public async Task<IActionResult> CreateGenre([FromBody] CreateGenreDto dto)
        {
            try
            {
                var newGenre = await _genre.CreateGenre(dto);

                return Ok(newGenre);
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [Authorize(Policy = "AdminOnly")]
        [HttpPut("update-genre/{id}")]
        public async Task<IActionResult> UpdateGenre([FromBody] UpdateGenreDto dto, int id)
        {
            try
            {
                var updateGenre = await _genre.UpdateGenre(dto, id);

                return Ok(updateGenre);
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [Authorize(Policy = "AdminOnly")]
        [HttpDelete("delete-genre/{id}")]
        public async Task<IActionResult> DeleteGenre(int id)
        {
            try
            {
                var deleteGenre = await _genre.DeleteGenre(id);

                _context.Genres.Remove(deleteGenre);
                await _context.SaveChangesAsync();

                throw new Result("Xóa thể loại thành công");
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }
    }
}