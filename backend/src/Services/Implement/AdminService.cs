using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Configurations;
using backend.src.Data;
using backend.src.Dtos.Admin;
using backend.src.Exceptions;
using backend.src.Models;
using backend.src.Services.Interface;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace backend.src.Services.Implement
{
    public class AdminService : IAdminService
    {
        private readonly ApplicationDbContext _context;
        private IMinioStorageService _minio;
        public AdminService(ApplicationDbContext context, IMinioStorageService minio)
        {
            _context = context;
            _minio = minio;
        }

        public async Task<List<Admin>> GetInfoAdmin()
        {
            var admin = await _context.Admins.ToListAsync();

            return admin;
        }

        public async Task<Admin> GetInfoAdminById(int id)
        {
            var admin = await _context.Admins.FirstOrDefaultAsync(a => a.Id == id);

            if (admin == null)
            {
                throw new Result("Admin không tồn tại");
            }

            return admin;
        }

        public async Task<string> UploadImageForAdmin(IFormFile file)
        {
            if (file == null || file.Length == 0)
            {
                throw new ArgumentException("File không hợp lệ");
            }

            var filename = await _minio.UploadImageAsync(file, "AvatarAdmin");

            return filename;
        }

        public async Task<Admin> CreateAdmin(CreateAdminDto adminDto)
        {
            var checkUserNameAdmin = await _context.Users.FirstOrDefaultAsync(a => a.UserName == adminDto.UserName);
            if (checkUserNameAdmin != null)
            {
                throw new Result("Tên đăng nhập đã tồn tại");
            }

            var checkEmailAdmin = await _context.Admins.FirstOrDefaultAsync(a => a.Email == adminDto.Email);
            if (checkEmailAdmin != null)
            {
                throw new Result("Email đã tồn tại");
            }

            var checkPhoneAdmin = await _context.Admins.FirstOrDefaultAsync(a => a.Phone == adminDto.Phone);
            if (checkPhoneAdmin != null)
            {
                throw new Result("Số điện thoại đã tồn tại");
            }

            if (string.IsNullOrWhiteSpace(adminDto.Birth))
            {
                throw new Result("Ngày sinh không được để trống");
            }

            var allowedFormats = new[] { "dd/MM/yyyy", "yyyy-MM-dd" };
            if (!DateOnly.TryParseExact(adminDto.Birth, allowedFormats, CultureInfo.InvariantCulture, DateTimeStyles.None, out var parsedBirth))
            {
                throw new Result("Ngày sinh không hợp lệ. Vui lòng dùng dd/MM/yyyy hoặc yyyy-MM-dd");
            }

            if (string.IsNullOrWhiteSpace(adminDto.Password))
            {
                throw new Result("Mật khẩu không được để trống");
            }

            // hash password
            var hashPassword = PasswordHelper.HashPassword(adminDto.Password);

            // tạo user mới 
            var newUserAdmin = new Users
            {
                UserName = adminDto.UserName,
                Password = hashPassword,
                Role = "Admin"
            };

            await _context.Users.AddAsync(newUserAdmin);
            await _context.SaveChangesAsync();

            // tạo thông tin admin
            var newInfoAdmin = new Admin
            {
                Name = adminDto.Name,
                Birth = parsedBirth,
                Gender = adminDto.Gender,
                Email = adminDto.Email,
                Avatar = adminDto.Avatar,
                Phone = adminDto.Phone,
                Address = adminDto.Address,
                UserId = newUserAdmin.Id
            };

            await _context.Admins.AddAsync(newInfoAdmin);
            await _context.SaveChangesAsync();

            return newInfoAdmin;
        }

        public async Task<Admin> UpdateAdmin(UpdateAdminDto adminDto, int id) 
        {
            var admin = await _context.Admins.FindAsync(id);
            if (admin == null)
            {
                throw new Result("Admin không tồn tại");
            }

            if (string.IsNullOrWhiteSpace(adminDto.Birth))
            {
                throw new Result("Ngày sinh không được để trống");
            }

            var allowedFormats = new[] { "dd/MM/yyyy", "yyyy-MM-dd" };
            if (!DateOnly.TryParseExact(adminDto.Birth, allowedFormats, CultureInfo.InvariantCulture, DateTimeStyles.None, out var parsedBirth))
            {
                throw new Result("Ngày sinh không hợp lệ. Vui lòng dùng dd/MM/yyyy hoặc yyyy-MM-dd");
            }

            admin.Address = adminDto.Address;
            admin.Avatar = adminDto.Avatar;
            admin.Birth = parsedBirth;
            admin.Email = adminDto.Email;
            var checkEmailAdmin = await _context.Admins.FirstOrDefaultAsync(a => a.Email == adminDto.Email && a.Id != id);
            if (checkEmailAdmin != null)
            {
                throw new Result("Email đã tồn tại");
            }

            var checkPhoneAdmin = await _context.Admins.FirstOrDefaultAsync(a => a.Phone == adminDto.Phone && a.Id != id);
            if (checkPhoneAdmin != null)
            {
                throw new Result("Số điện thoại đã tồn tại");
            }

            admin.Gender = adminDto.Gender;
            admin.Name = adminDto.Name;
            admin.Phone = adminDto.Phone;

            // Chuyển path thành URL khi trả về
            if (!string.IsNullOrEmpty(admin.Avatar))
            {
                admin.Avatar = _minio.GetImageUrl(admin.Avatar);
            }

            await _context.SaveChangesAsync();

            return admin;
        }

        public async Task<Admin> DeleteAdmin(int id) 
        {
            var admin = await _context.Admins.FindAsync(id);
            if (admin == null) {
                throw new Result("Không tìm thấy admin cần xóa");
            }

            var userAdmin = await _context.Users.FindAsync(admin.UserId);
            if (userAdmin != null)
            {
                _context.Users.Remove(userAdmin);
            }

            // xóa admin
            _context.Admins.Remove(admin);
            await _context.SaveChangesAsync();

            return admin;
        }

        public async Task<List<Readers>> GetInfoReader()
        {
            var readers = await _context.Readers.ToListAsync();

            return readers;
        }

        public async Task<Readers> GetInfoReaderById(int id)
        {
            var reader = await _context.Readers.FirstOrDefaultAsync(r => r.Id == id);

            if (reader == null)
            {
                throw new Result("Người dùng không tồn tại");
            }

            return reader;
        }

        public async Task<string> UploadImageForReader(IFormFile file)
        {
            if (file == null || file.Length == 0)
            {
                throw new ArgumentException("File không hợp lệ");
            }

            var filename = await _minio.UploadImageAsync(file, "AvatarReader");

            return filename;
        }

        public async Task<Readers> CreateReader(CreateReaderDto readerDto)
        {
            var checkUserNameReader = await _context.Users.FirstOrDefaultAsync(a => a.UserName == readerDto.UserName);
            if (checkUserNameReader != null)
            {
                throw new Result("Tên đăng nhập đã tồn tại");
            }

            var checkEmailReader = await _context.Readers.FirstOrDefaultAsync(a => a.Email == readerDto.Email);
            if (checkEmailReader != null)
            {
                throw new Result("Email đã tồn tại");
            }

            var checkPhoneReader = await _context.Readers.FirstOrDefaultAsync(a => a.Phone == readerDto.Phone);
            if (checkPhoneReader != null)
            {
                throw new Result("Số điện thoại đã tồn tại");
            }

            if (string.IsNullOrWhiteSpace(readerDto.Password))
            {
                throw new Result("Mật khẩu không được để trống");
            }

            var hashPassword = PasswordHelper.HashPassword(readerDto.Password);

            var newUserReader = new Users
            {
                UserName = readerDto.UserName,
                Password = hashPassword,
                Role = "Reader"
            };

            await _context.Users.AddAsync(newUserReader);
            await _context.SaveChangesAsync();

            var newInfoReader = new Readers
            {
                FullName = readerDto.FullName,
                Birth = readerDto.Birth,
                Gender = readerDto.Gender,
                Email = readerDto.Email,
                Avatar = readerDto.Avatar,
                Phone = readerDto.Phone,
                Address = readerDto.Address,
                Coin = 0,
                UserId = newUserReader.Id
            };

            await _context.Readers.AddAsync(newInfoReader);
            await _context.SaveChangesAsync();

            return newInfoReader;
        }

        public async Task<Readers> UpdateReader(UpdateReaderDto readerDto, int id)
        {
            var reader = await _context.Readers.FindAsync(id);
            if (reader == null)
            {
                throw new Result("Reader không tồn tại");
            }

            var checkEmailReader = await _context.Readers.FirstOrDefaultAsync(a => a.Email == readerDto.Email && a.Id != id);
            if (checkEmailReader != null)
            {
                throw new Result("Email đã tồn tại");
            }

            var checkPhoneReader = await _context.Readers.FirstOrDefaultAsync(a => a.Phone == readerDto.Phone && a.Id != id);
            if (checkPhoneReader != null)
            {
                throw new Result("Số điện thoại đã tồn tại");
            }

            reader.Address = readerDto.Address;
            reader.Avatar = readerDto.Avatar;
            reader.Birth = readerDto.Birth;
            reader.Email = readerDto.Email;
            reader.Gender = readerDto.Gender;
            reader.FullName = readerDto.FullName;
            reader.Phone = readerDto.Phone;

            if (!string.IsNullOrEmpty(reader.Avatar))
            {
                reader.Avatar = _minio.GetImageUrl(reader.Avatar);
            }

            await _context.SaveChangesAsync();

            return reader;
        }

        public async Task<Readers> DeleteReader(int id)
        {
            var reader = await _context.Readers.FindAsync(id);
            if (reader == null)
            {
                throw new Result("Không tìm thấy reader cần xóa");
            }

            var userReader = await _context.Users.FindAsync(reader.UserId);
            if (userReader != null)
            {
                _context.Users.Remove(userReader);
            }

            _context.Readers.Remove(reader);
            await _context.SaveChangesAsync();

            return reader;
        }

        
    }
}