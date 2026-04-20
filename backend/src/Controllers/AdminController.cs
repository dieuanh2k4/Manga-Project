using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Data;
using backend.src.Dtos.Admin;
using backend.src.Models;
using backend.src.Services.Interface;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Minio;

namespace backend.src.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Policy = "AdminOnly")]
    public class AdminController : ApiControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IMinioStorageService _minio;
        private readonly IAdminService _admin;

        public AdminController(ApplicationDbContext context, IAdminService admin, IMinioStorageService minio, ILogger<AdminController> logger) : base(logger)
        {
            _context = context;
            _admin = admin;
            _minio = minio;
        }

        [HttpGet("get-info-admin")]
        public async Task<IActionResult> GetInfoAdmin()
        {
            try
            {
                var admin = await _admin.GetInfoAdmin();

                return Ok(admin);
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [HttpGet("get-admin-by-Id/{id:int}")]
        public async Task<IActionResult> GetAdminById(int id)
        {
            try
            {
                var admin = await _admin.GetInfoAdminById(id);

                return Ok(admin);
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [HttpPost("create-admin")]
        public async Task<IActionResult> CreateAdmin([FromForm] CreateAdminDto adminDto, IFormFile? file)
        {
            try
            {
                // Upload avatar
                if (file != null && file.Length > 0)
                {
                    try
                    {
                        var imageUrl = await _minio.UploadImageAsync(file);
                        adminDto.Avatar = imageUrl;
                    }
                    catch (Exception)
                    {
                        adminDto.Avatar = null;
                    }
                }

                var newAdmin = await _admin.CreateAdmin(adminDto);

                return Ok(new
                {
                    message = "Tạo Admin thành công",
                    user = newAdmin
                });
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [HttpPut("update-admin/{id}")]
        public async Task<IActionResult> UpdateAdmin([FromForm] UpdateAdminDto adminDto, IFormFile? file, int id)
        {
            try
            {
                // Upload avatar
                if (file != null && file.Length > 0)
                {
                    try
                    {
                        var imageUrl = await _minio.UploadImageAsync(file);
                        adminDto.Avatar = imageUrl;
                    }
                    catch (Exception)
                    {
                        adminDto.Avatar = null;
                    }
                }

                var updateAdmin = await _admin.UpdateAdmin(adminDto, id);

                return Ok(new
                {
                    message = "Cập nhật thành công",
                    user = updateAdmin
                });
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [HttpDelete("delete-admin/{id}")]
        public async Task<IActionResult> DeleteAdmin(int id)
        {
            try
            {
                var deleteAdmin = await _admin.DeleteAdmin(id);

                return Ok(new
                {
                    message = "Xóa Admin thành công",
                    user = deleteAdmin
                });
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [HttpGet("get-info-reader")]
        public async Task<IActionResult> GetInfoReader()
        {
            try
            {
                var reader = await _admin.GetInfoReader();

                return Ok(reader);
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [HttpGet("get-reader-by-id/{id:int}")]
        public async Task<IActionResult> GetReaderById(int id)
        {
            try
            {
                var reader = await _admin.GetInfoReaderById(id);

                return Ok(reader);
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [HttpPost("create-reader")]
        public async Task<IActionResult> CreateReader([FromForm] CreateReaderDto readerDto, IFormFile? file)
        {
            try
            {
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

                var newReader = await _admin.CreateReader(readerDto);

                return Ok(new
                {
                    message = "Tạo Reader thành công",
                    user = newReader
                });
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [HttpPut("update-reader/{id}")]
        public async Task<IActionResult> UpdateReader([FromForm] UpdateReaderDto readerDto, IFormFile? file, int id)
        {
            try
            {
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
                    message = "Cập nhật Reader thành công",
                    user = updateReader
                });
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [HttpDelete("delete-reader/{id}")]
        public async Task<IActionResult> DeleteReader(int id)
        {
            try
            {
                var deleteReader = await _admin.DeleteReader(id);

                return Ok(new
                {
                    message = "Xóa Reader thành công",
                    user = deleteReader
                });
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [AllowAnonymous]
        [HttpGet("reader-management")]
        public async Task<IActionResult> GetReaderManagement([FromQuery] ReaderManagementQueryDto query)
        {
            try
            {
                var page = await _admin.GetReaderManagement(query);
                return Ok(page);
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [AllowAnonymous]
        [HttpPost("reader-management")]
        public async Task<IActionResult> CreateReaderManagement([FromBody] CreateReaderManagementDto dto)
        {
            try
            {
                var user = await _admin.CreateReaderManagement(dto);
                return Ok(user);
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [AllowAnonymous]
        [HttpPut("reader-management/{id:int}")]
        public async Task<IActionResult> UpdateReaderManagement(int id, [FromBody] UpdateReaderManagementDto dto)
        {
            try
            {
                var user = await _admin.UpdateReaderManagement(id, dto);
                return Ok(user);
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [AllowAnonymous]
        [HttpPost("reader-management/{id:int}/reset-password")]
        public async Task<IActionResult> ResetReaderPassword(int id, [FromBody] ResetPasswordRequestDto dto)
        {
            try
            {
                var user = await _admin.ResetReaderPassword(id, dto);
                return Ok(user);
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [AllowAnonymous]
        [HttpPost("reader-management/{id:int}/grant-vip")]
        public async Task<IActionResult> GrantReaderVip(int id, [FromBody] GrantVipRequestDto dto)
        {
            try
            {
                var user = await _admin.GrantReaderVip(id, dto);
                return Ok(user);
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [AllowAnonymous]
        [HttpPost("reader-management/{id:int}/revoke-vip")]
        public async Task<IActionResult> RevokeReaderVip(int id)
        {
            try
            {
                var user = await _admin.RevokeReaderVip(id);
                return Ok(user);
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [AllowAnonymous]
        [HttpPost("reader-management/{id:int}/mute-comment")]
        public async Task<IActionResult> MuteReaderComment(int id)
        {
            try
            {
                var user = await _admin.MuteReaderComment(id);
                return Ok(user);
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [AllowAnonymous]
        [HttpPost("reader-management/{id:int}/unmute-comment")]
        public async Task<IActionResult> UnmuteReaderComment(int id)
        {
            try
            {
                var user = await _admin.UnmuteReaderComment(id);
                return Ok(user);
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [AllowAnonymous]
        [HttpPost("reader-management/{id:int}/ban")]
        public async Task<IActionResult> BanReader(int id)
        {
            try
            {
                var user = await _admin.BanReader(id);
                return Ok(user);
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [AllowAnonymous]
        [HttpPost("reader-management/{id:int}/unban")]
        public async Task<IActionResult> UnbanReader(int id)
        {
            try
            {
                var user = await _admin.UnbanReader(id);
                return Ok(user);
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [AllowAnonymous]
        [HttpPost("reader-management/{id:int}/force-logout")]
        public async Task<IActionResult> ForceLogoutReader(int id)
        {
            try
            {
                var user = await _admin.ForceLogoutReader(id);
                return Ok(user);
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [AllowAnonymous]
        [HttpPost("reader-management/bulk-notify")]
        public async Task<IActionResult> BulkNotifyReaders([FromBody] BulkNotifyRequestDto dto)
        {
            try
            {
                var count = await _admin.BulkNotifyReaders(dto);
                return Ok(new { NotifiedCount = count });
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }
    }
}