using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Data;
using backend.src.Dtos.Previlage;
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
    public class PrevilagesController : ApiControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IPrevilageService _previlageservice;

        public PrevilagesController(ApplicationDbContext context, IPrevilageService previlageService, ILogger<PrevilagesController> logger) : base(logger)
        {
            _context = context;
            _previlageservice = previlageService;
        }

        [HttpGet("get-all-previlage")]
        public async Task<IActionResult> GetAllPrevilage()
        {
            try
            {
                var previlages = await _context.Previlages.ToListAsync();

                if (previlages == null)
                {
                    throw new Result("Chưa có đặc quyền nào");
                }

                return Ok(new
                {
                    message = "Lấy đặc quyền thành công",
                    data = previlages
                });
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [HttpPost("create-previlage")]
        public async Task<IActionResult> CreatePrevilage([FromBody] CreatePrevilageDto dto)
        {
            try
            {
                var newPrevilage = await _previlageservice.CreatePrevilage(dto);

                return Ok(new
                {
                    message = "Lấy đặc quyền thành công",
                    data = newPrevilage
                });
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [HttpPut("update-previlage/{id}")]
        public async Task<IActionResult> UpdatePrevilage([FromBody] UpdatePrevilageDto dto, int id)
        {
            try
            {
                var updatePrevilage = await _previlageservice.UpdatePrevilage(dto, id);

                return Ok(new
                {
                    message = "Cập nhật đặc quyền thành công",
                    data = updatePrevilage
                });
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [HttpDelete("delete-previlage/{id}")]
        public async Task<IActionResult> DeletePrevilage(int id)
        {
            try
            {
                var deletePrevilage = await _previlageservice.DeletePrevilage(id);

                return Ok(new
                {
                    message = "Xóa đặc quyền thành công",
                    data = deletePrevilage
                });
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }
    }
}