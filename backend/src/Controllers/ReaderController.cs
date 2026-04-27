using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Data;
using backend.src.Dtos.Admin;
using backend.src.Exceptions;
using backend.src.Services.Interface;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace backend.src.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Policy = "ReaderOnly")]
    public class ReaderController : ApiControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IMinioStorageService _minio;
        private readonly IAdminService _admin;

        public ReaderController(ApplicationDbContext context, IAdminService admin, IMinioStorageService minio, ILogger<AdminController> logger) : base(logger)
        {
            _context = context;
            _admin = admin;
            _minio = minio;
        }

        [HttpGet("get-info-account")]
        public async Task<IActionResult> GetInfoReader()
        {
            try
            {
                var userId = GetCurrentUserId();
                if (userId == null)
                {
                    throw new UnauthorizedAccessException("Token khong hop le");
                }

                var readers = await _admin.GetInfoReader();
                var reader = readers.FirstOrDefault(r => r.UserId == userId.Value);
                if (reader == null)
                {
                    throw new KeyNotFoundException("Khong tim thay thong tin Reader");
                }

                if (!string.IsNullOrWhiteSpace(reader.Avatar) && !reader.Avatar.StartsWith("http", StringComparison.OrdinalIgnoreCase))
                {
                    reader.Avatar = await _minio.GetImageUrlAsync(reader.Avatar);
                }

                return Ok(reader);
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [HttpPut("update-account")]
        public async Task<IActionResult> UpdateReader([FromForm] UpdateReaderDto readerDto, IFormFile? file, int id)
        {
            try
            {
                var uploadStatus = file != null && file.Length > 0 ? "Đang xử lý" : null;

                // Upload avatar
                if (file != null && file.Length > 0)
                {
                    try
                    {
                        var imageUrl = await _minio.UploadImageAsync(file);
                        readerDto.Avatar = imageUrl;
                    }
                    catch (Exception)
                    {
                        readerDto.Avatar = null;
                    }
                }

                var updateReader = await _admin.UpdateReader(readerDto, id);

                return Ok(new
                {
                    message = "Cập nhật account thành công",
                    uploadStatus,
                    user = updateReader
                });
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [HttpDelete("delete-account")]
        public async Task<IActionResult> DeleteReader(int id)
        {
            try
            {
                var deleteReader = await _admin.DeleteReader(id);

                return Ok(new
                {
                    message = "Xóa account thành công",
                    user = deleteReader
                });
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }
    }
}