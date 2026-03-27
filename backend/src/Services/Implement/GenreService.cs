using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Data;
using backend.src.Dtos.Genre;
using backend.src.Exceptions;
using backend.src.Mappers;
using backend.src.Models;
using backend.src.Services.Interface;
using Microsoft.EntityFrameworkCore;

namespace backend.src.Services.Implement
{
    public class GenreService : IGenreService
    {
        private readonly ApplicationDbContext _context;

        public GenreService(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<List<Genres>> GetAllGenre()
        {
            return await _context.Genres.ToListAsync();
        }

        public async Task<Genres> CreateGenre(CreateGenreDto dto)
        {
            if (string.IsNullOrWhiteSpace(dto.Name))
            {
                throw new Result("Tên thể loại không được để trống");
            }

            var genreName = dto.Name.Trim();

            var checkGenreName = await _context.Genres
                .FirstOrDefaultAsync(g => g.Name != null && g.Name.ToLower() == genreName.ToLower());

            if (checkGenreName != null)
            {
                throw new Result($"Thể loại {genreName} đã tồn tại.");
            }

            dto.Name = genreName;

            var newGenre = await dto.FromDtoToGenre();

            await _context.AddAsync(newGenre);
            await _context.SaveChangesAsync();

            return newGenre;
        }

        public async Task<Genres> UpdateGenre(UpdateGenreDto dto, int id)
        {
            var genre = await _context.Genres.FindAsync(id);

            if (genre == null)
            {
                throw new Result("Thể loại không tồn tại");
            }

            if (string.IsNullOrWhiteSpace(dto.Name))
            {
                throw new Result("Tên thể loại không được để trống");
            }

            var genreName = dto.Name.Trim();

            var checkGenreName = await _context.Genres
                .FirstOrDefaultAsync(g => g.Id != id && g.Name != null && g.Name.ToLower() == genreName.ToLower());

            if (checkGenreName != null)
            {
                throw new Result($"Thể loại {genreName} đã tồn tại.");
            }

            genre.Name = genreName;

            await _context.SaveChangesAsync();

            return genre;
        }

        public async Task<Genres> DeleteGenre(int id)
        {
            var genre = await _context.Genres.FindAsync(id);

            if (genre == null)
            {
                throw new Result("Thể loại không tồn tại");
            }

            return genre;
        }
    }
}