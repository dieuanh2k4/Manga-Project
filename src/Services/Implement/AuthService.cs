using System;
using System.Collections.Generic;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Configurations;
using backend.src.Data;
using backend.src.Dtos.Auth;
using backend.src.Exceptions;
using backend.src.Models;
using backend.src.Services.Interface;
using Microsoft.EntityFrameworkCore;

namespace backend.src.Services.Implement
{
    public class AuthService : IAuthService
    {
        private readonly ApplicationDbContext _context;
        private readonly JwtHelper _jwtHelper;
        public AuthService(ApplicationDbContext context, JwtHelper jwtHelper)
        {
            _context = context;
            _jwtHelper = jwtHelper;
        }

        public async Task<AuthResultDto> Login(LoginRequestDto request)
        {
            // tìm user theo username và role
            var user = await _context.Users
                .Include(u => u.Role)
                .FirstOrDefaultAsync(u => u.UserName == request.UserName);

            if (user == null)
            {
                return AuthResultDto.Fail("Sai tài khoản hoặc mật khẩu");
            }

            // Verify password
            if (!PasswordHelper.VerifyPassword(request.Password, user.Password))
            {
                return AuthResultDto.Fail("Sai tài khoản hoặc mật khẩu");
            }

            var token = _jwtHelper.CreateToken(user.UserName, user.Role, user.Id);

            var response = new LoginResponseDto
            {
                UserName = user.UserName,
                Role = user.Role,
                Token = token
            };

            return AuthResultDto.Success(response, "Đăng nhập thành công");
        }

        public async Task<Users> Register(RegisterDto register)
        {
            // Validate các trường bắt buộc
            if (string.IsNullOrWhiteSpace(register.UserName))
                throw new Result("Tên đăng nhập không được để trống");
            if (string.IsNullOrWhiteSpace(register.Password))
                throw new Result("Tên đăng nhập không được để trống");

            // kiểm tra username
            var checkUserName = await _context.Users
                .FirstOrDefaultAsync(a => a.UserName == register.UserName);
            if (checkUserName != null)
            {
                throw new Result("Tên đăng nhập đã tồn tại");
            }

            // hash password
            var hashPassword = PasswordHelper.HashPassword(register.Password);

            // tạo user mới
            var newUser = new Users
            {
                UserName = register.UserName,
                Password = register.Password,
                Role = "Reader"
            };

            newUser.Password = hashPassword;

            await _context.Users.AddAsync(newUser);
            await _context.SaveChangesAsync();

            return newUser;
        }
    }
}