using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Data;
using backend.src.Dtos.Package;
using backend.src.Exceptions;
using backend.src.Services.Interface;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace backend.src.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PackageController : ApiControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IPackageService _packageservice;

        public PackageController(ApplicationDbContext context, IPackageService packageService, ILogger<PackageController> logger) : base(logger)
        {
            _context = context;
            _packageservice = packageService;
        }

        [AllowAnonymous]
        [HttpGet("get-all-package")]
        public async Task<IActionResult> GetAllPackge()
        {
            try
            {
                var packages = await _context.Packages
                    .Include(a => a.Previlages)
                    .ToListAsync();

                if (packages.Count == 0)
                {
                    throw new Result("Chưa có package nào");
                }

                var packageData = packages.Select(package => new
                {
                    package.Id,
                    package.Title,
                    package.Price,
                    Previlages = package.Previlages.Select(p => new
                    {
                        p.Id,
                        p.Content
                    })
                });

                return Ok(new
                {
                    message = "Lấy package thành công",
                    data = packageData
                });
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [Authorize(Policy = "AdminOnly")]
        [HttpPost("create-package")]
        public async Task<IActionResult> CreatePackage([FromBody] CreatePackageDto dto)
        {
            try
            {
                var newpackage = await _packageservice.CreatePackage(dto);

                return Ok(new
                {
                    message = "Tạo package thành công",
                    data = newpackage
                });
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [Authorize(Policy = "AdminOnly")]
        [HttpPut("update-package/{id}")]
        public async Task<IActionResult> UpdatePackage([FromBody] UpdatePackageDto dto, int id)
        {
            try
            {
                var updatepackage = await _packageservice.UpdatePackage(dto, id);

                return Ok(new
                {
                    message = "Cập nhật package thành công",
                    data = updatepackage
                });
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [Authorize(Policy = "AdminOnly")]
        [HttpPut("delete-package/{id}")]
        public async Task<IActionResult> DeletePackage(int id)
        {
            try
            {
                var deletepackage = await _packageservice.DeletePackage(id);

                return Ok(new
                {
                    message = "Xóa package thành công",
                    data = deletepackage
                });
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [Authorize(Policy = "ReaderOnly")]
        [HttpPost("purchase/{packageId}")]
        public async Task<IActionResult> PurchasePackage(int packageId)
        {
            try
            {
                var userId = GetCurrentUserId();
                if (userId == null)
                {
                    throw new UnauthorizedAccessException("Không xác định được người dùng");
                }

                var purchase = await _packageservice.PurchasePackage(packageId, userId.Value);

                return Ok(new
                {
                    message = "Mua package thành công",
                    data = purchase
                });
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }
    }
}