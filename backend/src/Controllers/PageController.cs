using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Data;
using backend.src.Services.Interface;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace backend.src.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PageController : ApiControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IPageService _page;
        
        public PageController(ApplicationDbContext context, IPageService page, ILogger<PageController> logger) : base(logger)
        {
            _context = context;
            _page = page;
        }

        [AllowAnonymous] 
        [HttpGet("get-all-page/{idManga}/{idChapter}")]
        public async Task<IActionResult> GetAllPage(int idManga, int idChapter)
        {
            try
            {
                var userId = GetCurrentUserId();
                var page = await _page.GetAllPage(idManga, idChapter, userId);

                return Ok(page);
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [Authorize(Policy = "AdminOnly")] 
        [Consumes("multipart/form-data")]
        [HttpPost("add-page/{idManga}/{idChapter}")]
        public async Task<IActionResult> AddPageToChapter([FromRoute] int idManga, [FromRoute] int idChapter, [FromForm(Name = "files")] List<IFormFile> files)
        {
            try
            {
                var pages = await _page.AddPageToChapter(idManga, idChapter, files);
                var uploadStatus = files != null && files.Count > 0 ? "Đang xử lý" : null;

                return Ok(new
                {
                    message = "Thêm page thành công",
                    uploadStatus,
                    data = pages
                });
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [Authorize(Policy = "AdminOnly")] 
        [HttpPost("delete-page/{idManga}/{idChapter}")]
        public async Task<IActionResult> DeletePageOfChapter([FromRoute] int idManga, [FromRoute] int idChapter, [FromForm] List<int> pageIds)
        {
            try
            {
                var pages = await _page.DeletePageOfChapter(idManga, idChapter, pageIds);

                return Ok(new
                {
                    message = "Xóa page thành công",
                    data = pages
                });
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }
    }
}