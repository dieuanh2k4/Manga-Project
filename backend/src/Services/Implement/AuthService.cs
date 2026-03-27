using System;
using System.Collections.Generic;
using System.Globalization;
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
        private readonly IMinioStorageService _minio;

        public AuthService(ApplicationDbContext context, JwtHelper jwtHelper, IMinioStorageService minio)
        {
            _context = context;
            _jwtHelper = jwtHelper;
            _minio = minio;
        }

        public async Task<AuthResultDto> Login(LoginRequestDto request)
        {
            // tìm user theo username và role
            var user = await _context.Users
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

        public async Task<string> UploadImage(IFormFile file)
        {
            if (file == null || file.Length == 0)
            {
                throw new ArgumentException("File không hợp lệ");
            }

            var filename = await _minio.UploadImageAsync(file, "AvatarReader");

            return filename;
        }

        public async Task<Users> Register(RegisterDto register)
        {
            // Validate các trường bắt buộc
            if (string.IsNullOrWhiteSpace(register.UserName))
                throw new Result("Tên đăng nhập không được để trống");
            if (string.IsNullOrWhiteSpace(register.Password))
                throw new Result("Tên đăng nhập không được để trống");
            
            var checkUserNameReader = await _context.Users.FirstOrDefaultAsync(a => a.UserName == register.UserName);
            if (checkUserNameReader != null)
            {
                throw new Result("Tên đăng nhập đã tồn tại");
            }

            var checkEmailReader = await _context.Readers.FirstOrDefaultAsync(a => a.Email == register.Email);
            if (checkEmailReader != null)
            {
                throw new Result("Email đã tồn tại");
            }

            var checkPhoneReader = await _context.Readers.FirstOrDefaultAsync(a => a.Phone == register.Phone);
            if (checkPhoneReader != null)
            {
                throw new Result("Số điện thoại đã tồn tại");
            }

            if (string.IsNullOrWhiteSpace(register.Password))
            {
                throw new Result("Mật khẩu không được để trống");
            }

            if (string.IsNullOrWhiteSpace(register.Birth))
            {
                throw new Result("Ngày sinh không được để trống");
            }

            var allowedFormats = new[] { "dd/MM/yyyy", "yyyy-MM-dd" };
            if (!DateOnly.TryParseExact(register.Birth, allowedFormats, CultureInfo.InvariantCulture, DateTimeStyles.None, out var parsedBirth))
            {
                throw new Result("Ngày sinh không hợp lệ. Vui lòng dùng dd/MM/yyyy hoặc yyyy-MM-dd");
            }

            // hash password
            var hashPassword = PasswordHelper.HashPassword(register.Password);

            // tạo user mới
            var newUser = new Users
            {
                UserName = register.UserName,
                Password = hashPassword,
                Role = "Reader"
            };

            await _context.Users.AddAsync(newUser);
            await _context.SaveChangesAsync();

            var newInfoReader = new Readers
            {
                FullName = register.FullName,
                Birth = parsedBirth,
                Gender = register.Gender,
                Email = register.Email,
                Avatar = register.Avatar,
                Phone = register.Phone,
                Address = register.Address,
                Coin = 0,
                UserId = newUser.Id
            };

            await _context.Readers.AddAsync(newInfoReader);
            await _context.SaveChangesAsync();

            return newUser;
        }
    }
}