using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Data;
using backend.src.Dtos.Manga;
using backend.src.Exceptions;
using backend.src.Mappers;
using backend.src.Models;
using backend.src.Services.Interface;
using Microsoft.EntityFrameworkCore;

namespace backend.src.Services.Implement
{
    public class MangaService : IMangaService
    {
        private readonly ApplicationDbContext _context;
        private readonly IMinioStorageService _minio;

        public MangaService(ApplicationDbContext context, IMinioStorageService minio)
        {
            _context = context;
            _minio = minio;
        }

        public async Task<List<Manga>> GetAllManga()
        {
            var mangas = await _context.Manga
                .Include(m => m.Genres)
                .ToListAsync();

            foreach (var manga in mangas)
            {
                if (!string.IsNullOrEmpty(manga.Thumbnail))
                {
                    manga.Thumbnail = _minio.GetImageUrl(manga.Thumbnail);
                }
            }

            return mangas;
        }

        public async Task<Manga> GetAllMangaById(int id)
        {
            var manga = await _context.Manga
                .Include(m => m.Genres)
                .FirstOrDefaultAsync(m => m.Id == id);

            if (manga != null && !string.IsNullOrEmpty(manga.Thumbnail))
            {
                manga.Thumbnail = _minio.GetImageUrl(manga.Thumbnail);
            }

            return manga;
        }

        public async Task<string> UploadImage(IFormFile file)
        {
            if (file == null || file.Length == 0)
            {
                throw new ArgumentException("File không hợp lệ");
            }

            // Upload lên MinIO với folder "ThumbnailManga"
            // Trả về path để lưu vào DB: bucket/ThumbnailManga/abc.jpg
            var fileName = await _minio.UploadImageAsync(file, "ThumbnailManga");

            return fileName;
        }

        public async Task<Manga> CreateManga(CreateMangaDto dto)
        {
            if (dto.Title == null)
            {
                throw new Result("Tiêu đề Manga không được để trống");
            }

            var newManga = await dto.FromDtoToManga();

            newManga.Thumbnail = dto.Thumbnail;

            await _context.AddAsync(newManga);
            await _context.SaveChangesAsync();

            return newManga;
        }

        public async Task<Manga> UpdateManga(UpdateMangaDto dto, int id) 
        {
            var manga = await _context.Manga.FindAsync(id);

            if (manga == null) 
            {
                throw new Result($"Không tìm thấy Manga cần chỉnh sửa");
            }

            manga.AuthorId = dto.AuthorId;
            manga.ReleaseDate = dto.ReleaseDate;
            manga.GenreIds = dto.GenreIds;
            manga.Status = dto.Status;
            manga.TotalChapter = dto.TotalChapter;
            manga.Description = dto.Description;
            manga.Rate = dto.Rate;
            manga.Thumbnail = dto.Thumbnail;
            manga.Title = dto.Title;
            manga.EndDate = dto.EndDate;

            await _context.SaveChangesAsync();

            return manga;
        }

        public async Task<Manga> DeleteManga(int id) 
        {
            var manga = await _context.Manga.FindAsync(id);

            if (manga == null) 
            {
                throw new Result("Manga không tồn tại");
            }

            return manga;
        }

        public async Task<List<Manga>> Search(string query)
        {
            if (string.IsNullOrWhiteSpace(query))
            {
                return new List<Manga>();
            }

            var keyword = query.Trim(); // bỏ khoảng trắng
            var pattern = $"%{keyword}%"; // tìm kiểu chứa chuỗi con trong SQL

            var search = await _context.Manga
                .Where(manga =>
                    (manga.Title != null && EF.Functions.ILike(manga.Title, pattern)) ||
                    manga.Authors.Any(author => author.FullName != null && EF.Functions.ILike(author.FullName, pattern)))
                .OrderByDescending(a => a.Title)
                .ToListAsync();
            
            return search;
        }
        
        public async Task<List<Manga>> SortByGenre(int genreId)
        {
            var check = await _context.Genres.FirstOrDefaultAsync(g => g.Id == genreId);
            if (check == null) 
            {
                throw new Result("Không tìm thấy thể loại");
            }

            var sort = await _context.Manga
                .Where(m => m.GenreIds != null && m.GenreIds.Contains(genreId))
                .OrderByDescending(m => m.Title)
                .ToListAsync();
            
            return sort;
        }

        public async Task<List<Manga>> MangaOngoing()
        {
            var manga = await _context.Manga
                .Where(m => m.Status.ToLower() == "Đang tiến hành".ToLower())
                .OrderByDescending(m => m.Title)
                .ToListAsync();
            
            return manga;
        }

        public async Task<List<Manga>> MangaComplete()
        {
            var manga = await _context.Manga
                .Where(m => m.Status.ToLower() == "Hoàn thành".ToLower())
                .OrderByDescending(m => m.Title)
                .ToListAsync();
            
            return manga;
        }
    }
}