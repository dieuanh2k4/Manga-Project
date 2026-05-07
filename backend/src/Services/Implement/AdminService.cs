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
            var admin = await _context.Admins.Include(a => a.Users).ToListAsync();

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
                admin.Avatar = await _minio.GetImageUrlAsync(admin.Avatar);
            }

            await _context.SaveChangesAsync();

            return admin;
        }

        public async Task<Admin> DeleteAdmin(int id)
        {
            var admin = await _context.Admins.FindAsync(id);
            if (admin == null)
            {
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
                IsPremium = false,
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
                reader.Avatar = await _minio.GetImageUrlAsync(reader.Avatar);
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

        private static ReaderManagementItemDto ToReaderManagementItem(Readers reader)
        {
            return new ReaderManagementItemDto
            {
                Id = reader.Id,
                FullName = reader.FullName,
                Email = reader.Email,
                UserName = reader.Users?.UserName,
                Phone = reader.Phone,
                Address = reader.Address,
                Gender = reader.Gender,
                RegisteredAt = reader.RegisteredAt,
                IsCommentMuted = reader.IsCommentMuted,
                IsBanned = reader.IsBanned,
                MembershipTier = reader.IsPremium ? "VIP" : "Standard"
            };
        }

        private async Task<Readers> GetReaderIncludeUser(int id)
        {
            var reader = await _context.Readers
                .Include(r => r.Users)
                .FirstOrDefaultAsync(r => r.Id == id);

            if (reader == null)
            {
                throw new Result("Người dùng không tồn tại");
            }

            return reader;
        }

        public async Task<ReaderManagementPageDto> GetReaderManagement(ReaderManagementQueryDto query)
        {
            var page = query.Page <= 0 ? 1 : query.Page;
            var pageSize = query.PageSize <= 0 ? 10 : Math.Min(query.PageSize, 100);
            var search = (query.Search ?? string.Empty).Trim().ToLower();
            var membership = (query.Membership ?? "Tất cả").Trim();
            var sortBy = (query.SortBy ?? "fullName").Trim().ToLower();
            var sortDir = (query.SortDir ?? "desc").Trim().ToLower();
            var asc = sortDir == "asc";

            var readers = await _context.Readers
                .Include(r => r.Users)
                .ToListAsync();

            var filtered = readers.Where(reader =>
            {
                var userName = reader.Users?.UserName ?? string.Empty;
                var membershipLabel = reader.IsPremium ? "VIP" : "Standard";

                var matchesSearch = string.IsNullOrEmpty(search)
                    || (reader.FullName ?? string.Empty).ToLower().Contains(search)
                    || (reader.Email ?? string.Empty).ToLower().Contains(search)
                    || userName.ToLower().Contains(search);

                var matchesMembership = membership == "Tất cả" || string.Equals(membershipLabel, membership, StringComparison.OrdinalIgnoreCase);

                return matchesSearch && matchesMembership;
            });

            filtered = sortBy switch
            {
                "fullname" => asc
                    ? filtered.OrderBy(r => r.FullName)
                    : filtered.OrderByDescending(r => r.FullName),
                "email" => asc
                    ? filtered.OrderBy(r => r.Email)
                    : filtered.OrderByDescending(r => r.Email),
                "username" => asc
                    ? filtered.OrderBy(r => r.Users != null ? r.Users.UserName : string.Empty)
                    : filtered.OrderByDescending(r => r.Users != null ? r.Users.UserName : string.Empty),
                "phone" => asc
                    ? filtered.OrderBy(r => r.Phone)
                    : filtered.OrderByDescending(r => r.Phone),
                "address" => asc
                    ? filtered.OrderBy(r => r.Address)
                    : filtered.OrderByDescending(r => r.Address),
                "gender" => asc
                    ? filtered.OrderBy(r => r.Gender)
                    : filtered.OrderByDescending(r => r.Gender),
                "membership" => asc
                    ? filtered.OrderBy(r => r.IsPremium)
                    : filtered.OrderByDescending(r => r.IsPremium),
                "registeredat" => asc
                    ? filtered.OrderBy(r => r.RegisteredAt)
                    : filtered.OrderByDescending(r => r.RegisteredAt),
                _ => asc
                    ? filtered.OrderBy(r => r.FullName)
                    : filtered.OrderByDescending(r => r.FullName)
            };

            var total = filtered.Count();
            var items = filtered
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(ToReaderManagementItem)
                .ToList();

            return new ReaderManagementPageDto
            {
                Items = items,
                Total = total,
                Page = page,
                PageSize = pageSize
            };
        }

        public async Task<ReaderManagementItemDto> CreateReaderManagement(CreateReaderManagementDto dto)
        {
            if (string.IsNullOrWhiteSpace(dto.UserName))
            {
                throw new Result("Tên đăng nhập không được để trống");
            }

            if (string.IsNullOrWhiteSpace(dto.Password))
            {
                throw new Result("Mật khẩu không được để trống");
            }

            var existedUserName = await _context.Users.AnyAsync(u => u.UserName == dto.UserName);
            if (existedUserName)
            {
                throw new Result("Tên đăng nhập đã tồn tại");
            }

            var existedEmail = await _context.Readers.AnyAsync(r => r.Email == dto.Email);
            if (existedEmail)
            {
                throw new Result("Email đã tồn tại");
            }

            var user = new Users
            {
                UserName = dto.UserName,
                Password = PasswordHelper.HashPassword(dto.Password),
                Role = "Reader",
                TokenVersion = 0
            };

            await _context.Users.AddAsync(user);
            await _context.SaveChangesAsync();

            var reader = new Readers
            {
                FullName = dto.FullName,
                Email = dto.Email,
                Phone = dto.Phone,
                Address = dto.Address,
                Gender = dto.Gender,
                Birth = DateOnly.FromDateTime(DateTime.UtcNow),
                UserId = user.Id,
                IsPremium = false,
                IsCommentMuted = false,
                IsBanned = false,
                RegisteredAt = DateTime.UtcNow
            };

            await _context.Readers.AddAsync(reader);
            await _context.SaveChangesAsync();

            reader = await _context.Readers.Include(r => r.Users).FirstAsync(r => r.Id == reader.Id);
            return ToReaderManagementItem(reader);
        }

        public async Task<ReaderManagementItemDto> UpdateReaderManagement(int id, UpdateReaderManagementDto dto)
        {
            var reader = await GetReaderIncludeUser(id);

            if (!string.IsNullOrWhiteSpace(dto.Email))
            {
                var existedEmail = await _context.Readers.AnyAsync(r => r.Id != id && r.Email == dto.Email);
                if (existedEmail)
                {
                    throw new Result("Email đã tồn tại");
                }
            }

            if (!string.IsNullOrWhiteSpace(dto.UserName))
            {
                var existedUserName = await _context.Users.AnyAsync(u => u.Id != reader.UserId && u.UserName == dto.UserName);
                if (existedUserName)
                {
                    throw new Result("Tên đăng nhập đã tồn tại");
                }
            }

            reader.FullName = dto.FullName ?? reader.FullName;
            reader.Email = dto.Email ?? reader.Email;
            reader.Phone = dto.Phone ?? reader.Phone;
            reader.Address = dto.Address ?? reader.Address;
            reader.Gender = dto.Gender ?? reader.Gender;
            if (reader.Users != null && !string.IsNullOrWhiteSpace(dto.UserName))
            {
                reader.Users.UserName = dto.UserName;
            }

            await _context.SaveChangesAsync();
            return ToReaderManagementItem(reader);
        }

        public async Task<ReaderManagementItemDto> ResetReaderPassword(int id, ResetPasswordRequestDto dto)
        {
            var reader = await GetReaderIncludeUser(id);
            if (reader.Users == null)
            {
                throw new Result("Tài khoản đăng nhập không tồn tại");
            }

            var newPassword = string.IsNullOrWhiteSpace(dto.NewPassword)
                ? $"Temp{id}#{DateTime.UtcNow:MMdd}"
                : dto.NewPassword;

            reader.Users.Password = PasswordHelper.HashPassword(newPassword);
            await _context.SaveChangesAsync();

            var item = ToReaderManagementItem(reader);
            item.TempPassword = newPassword;
            return item;
        }

        public async Task<ReaderManagementItemDto> GrantReaderVip(int id, GrantVipRequestDto dto)
        {
            var reader = await GetReaderIncludeUser(id);
            reader.IsPremium = true;
            await _context.SaveChangesAsync();
            return ToReaderManagementItem(reader);
        }

        public async Task<ReaderManagementItemDto> RevokeReaderVip(int id)
        {
            var reader = await GetReaderIncludeUser(id);
            reader.IsPremium = false;
            await _context.SaveChangesAsync();
            return ToReaderManagementItem(reader);
        }

        public async Task<ReaderManagementItemDto> MuteReaderComment(int id)
        {
            var reader = await GetReaderIncludeUser(id);
            reader.IsCommentMuted = true;
            await _context.SaveChangesAsync();
            return ToReaderManagementItem(reader);
        }

        public async Task<ReaderManagementItemDto> UnmuteReaderComment(int id)
        {
            var reader = await GetReaderIncludeUser(id);
            reader.IsCommentMuted = false;
            await _context.SaveChangesAsync();
            return ToReaderManagementItem(reader);
        }

        public async Task<ReaderManagementItemDto> BanReader(int id)
        {
            var reader = await GetReaderIncludeUser(id);
            if (reader.Users == null)
            {
                throw new Result("Tài khoản đăng nhập không tồn tại");
            }

            reader.IsBanned = true;
            reader.Users.TokenVersion += 1;
            await _context.SaveChangesAsync();
            return ToReaderManagementItem(reader);
        }

        public async Task<ReaderManagementItemDto> UnbanReader(int id)
        {
            var reader = await GetReaderIncludeUser(id);
            reader.IsBanned = false;
            await _context.SaveChangesAsync();
            return ToReaderManagementItem(reader);
        }

        public async Task<ReaderManagementItemDto> ForceLogoutReader(int id)
        {
            var reader = await GetReaderIncludeUser(id);
            if (reader.Users == null)
            {
                throw new Result("Tài khoản đăng nhập không tồn tại");
            }

            reader.Users.TokenVersion += 1;
            await _context.SaveChangesAsync();
            return ToReaderManagementItem(reader);
        }

        public async Task<int> BulkNotifyReaders(BulkNotifyRequestDto dto)
        {
            if (dto.ReaderIds.Count == 0)
            {
                return 0;
            }

            var readers = await _context.Readers.Where(r => dto.ReaderIds.Contains(r.Id)).ToListAsync();

            var notification = new Notifications
            {
                Title = string.IsNullOrWhiteSpace(dto.Title) ? "Thông báo hệ thống" : dto.Title,
                Content = string.IsNullOrWhiteSpace(dto.Content) ? "Bạn có thông báo mới từ quản trị viên." : dto.Content,
                TargetRole = "Reader",
                MangaId = 0,
                CreatedAt = DateTime.UtcNow,
                IsRead = false
            };

            _context.Notifications.Add(notification);

            await _context.SaveChangesAsync();
            return readers.Count;
        }


    }
}