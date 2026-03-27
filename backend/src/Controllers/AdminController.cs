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

                return Ok(new {
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

                return Ok(new {
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
    }
}