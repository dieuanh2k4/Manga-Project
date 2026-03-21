using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Data;
using backend.src.Dtos.Auth;
using backend.src.Services.Interface;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Minio;

namespace backend.src.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ApiControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IAuthService _auth;

        public AuthController(ApplicationDbContext context, IAuthService auth, ILogger<AdminController> logger) : base(logger)
        {
            _context = context;
            _auth = auth;
        }

        [AllowAnonymous]
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequestDto request)
        {
            var result = await _auth.Login(request);
            if (!result.IsSuccess)
            {
                return BadRequest(result);
            }

            return Ok(result);
        }

        [AllowAnonymous] 
        [HttpPost("reader-register")]
        public async Task<IActionResult> Register([FromForm] RegisterDto register)
        {
            try
            {
                var newUser = await _auth.Register(register);
                return Ok(new
                {
                    message = "Đăng ký thành công",
                    user = newUser
                });
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }
    }
}