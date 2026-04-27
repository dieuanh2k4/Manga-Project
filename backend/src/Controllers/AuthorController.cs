using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Data;
using backend.src.Dtos.Author;
using backend.src.Exceptions;
using backend.src.Services.Interface;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace backend.src.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthorController: ApiControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IAuthorService _author;

        public AuthorController(ApplicationDbContext context, IAuthorService author, ILogger<AuthorController> logger) : base(logger)
        {
            _context = context;
            _author = author;
        }

        [AllowAnonymous]
        [HttpGet("get-all-author")]
        public async Task<IActionResult> GetAllAuthor()
        {
            try
            {
                var authors = await _author.GetAllAuthor();
                
                return Ok(authors);
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [AllowAnonymous]
        [HttpGet("get-author-by-id/{id}")]
        public async Task<IActionResult> GetAuthorById(int id)
        {
            try
            {
                var author = await _author.GetAllAuthorById(id);

                return Ok(author);
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [Authorize(Policy = "AdminOnly")]
        [HttpPost("create-author")]
        public async Task<IActionResult> CreateAuthor([FromForm] CreateAuthorDto dto, IFormFile? file)
        {
            try
            {
                if (file != null)
                {
                    var fileUrl = await _author.UploadImage(file);
                    dto.Avatar = fileUrl;
                    Response.Headers["X-Upload-Status"] = Uri.EscapeDataString("Đang xử lý");
                }

                var newAuthor = await _author.CreateAuthor(dto);

                return Ok(newAuthor);
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [Authorize(Policy = "AdminOnly")]
        [HttpPut("update-author/{id}")]
        public async Task<IActionResult> UpdateAuthor([FromForm] UpdateAuthorDto dto, IFormFile? file, int id)
        {
            try
            {
                if (file != null)
                {
                    var fileUrl = await _author.UploadImage(file);
                    dto.Avatar = fileUrl;
                    Response.Headers["X-Upload-Status"] = Uri.EscapeDataString("Đang xử lý");
                }

                var updateAuthor = await _author.UpdateAuthor(dto, id);

                return Ok(updateAuthor);
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [Authorize(Policy = "AdminOnly")]
        [HttpDelete("delete-author/{id}")]
        public async Task<IActionResult> DeleteAuthor(int id)
        {
            try
            {
                var deleteAuthor = await _author.DeleteAuthor(id);

                _context.Authors.Remove(deleteAuthor);
                await _context.SaveChangesAsync();

                throw new Result("Xóa tác giả thành công");
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }
    }
}