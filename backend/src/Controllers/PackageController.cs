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
    [Authorize(Policy = "AdminOnly")]
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

                return Ok(new
                {
                    message = "Lấy package thành công",
                    data = packages
                });
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

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
    }
}