using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Data;
using backend.src.Dtos.Author;
using backend.src.Exceptions;
using backend.src.Mappers;
using backend.src.Models;
using backend.src.Services.Interface;
using Microsoft.EntityFrameworkCore;

namespace backend.src.Services.Implement
{
    public class AuthorService : IAuthorService
    {
        private readonly ApplicationDbContext _context;
        private readonly IMinioStorageService _minio;
        
        public AuthorService(ApplicationDbContext context, IMinioStorageService minio)
        {
            _context = context;
            _minio = minio;
        }

        public async Task<List<Authors>> GetAllAuthor()
        {
            var authors = await _context.Authors.ToListAsync();

            // Chuyển path thành URL cho từng author
            foreach (var author in authors)
            {
                if (!string.IsNullOrEmpty(author.Avatar))
                {
                    author.Avatar = _minio.GetImageUrl(author.Avatar);
                }
            }

            return authors;
        }

        public async Task<Authors> GetAllAuthorById(int id)
        {
            var author = await _context.Authors.FirstOrDefaultAsync(m => m.Id == id);

            // Chuyển path thành URL cho từng author
            if (author != null && !string.IsNullOrEmpty(author.Avatar))
            {
                author.Avatar = _minio.GetImageUrl(author.Avatar);
            }

            return author;
        }

        public async Task<string> UploadImage(IFormFile file) 
        {
            if (file == null || file.Length == 0) {
                throw new ArgumentException("File không hợp lệ");
            }
            
            // Upload lên MinIO với folder "AvatarAuthors"
            // Trả về path để lưu vào DB: Manga/AvatarAuthors/abc.jpg
            var fileName = await _minio.UploadImageAsync(file, "AvatarAuthors");

            return fileName;
        }

        public async Task<Authors> CreateAuthor(CreateAuthorDto dto)
        {
            var checkAuthorName = await _context.Authors
                .FirstOrDefaultAsync(a => a.FullName.ToLower() == dto.FullName.ToLower());
            
            if (checkAuthorName != null) {
                throw new Result($"Tác giả {dto.FullName} đã tồn tại.");
            }

            var newAuthor = await dto.FromDtoToAuthor();

            newAuthor.Avatar = dto.Avatar;

            await _context.AddAsync(newAuthor);
            await _context.SaveChangesAsync();

            return newAuthor;
        }

        public async Task<Authors> UpdateAuthor(UpdateAuthorDto dto, int id)
        {
            var author = await _context.Authors.FindAsync(id);

            if (author == null)
            {
                throw new Result("Tác giả không tồn tại");
            }

            if (!string.IsNullOrWhiteSpace(dto.FullName))
            {
                var fullName = dto.FullName.Trim();

                var checkAuthorName = await _context.Authors
                    .FirstOrDefaultAsync(a => a.Id != id && a.FullName != null && a.FullName.ToLower() == fullName.ToLower());

                if (checkAuthorName != null)
                {
                    throw new Result($"Tác giả {fullName} đã tồn tại.");
                }

                author.FullName = fullName;
            }

            if (dto.Description != null)
            {
                author.Description = dto.Description;
            }

            if (!string.IsNullOrWhiteSpace(dto.Avatar))
            {
                author.Avatar = dto.Avatar;
            }

            await _context.SaveChangesAsync();

            if (!string.IsNullOrEmpty(author.Avatar))
            {
                author.Avatar = _minio.GetImageUrl(author.Avatar);
            }

            return author;
        }

        public async Task<Authors> DeleteAuthor(int id)
        {
            var author = await _context.Authors.FindAsync(id);

            if (author == null)
            {
                throw new Result("Tác giả không tồn tại");
            }

            return author;
        }
    }
}