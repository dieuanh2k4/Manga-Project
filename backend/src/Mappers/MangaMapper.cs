using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Dtos.Manga;
using backend.src.Models;

namespace backend.src.Mappers
{
    public static class MangaMapper
    {
        public static async Task<Manga> FromDtoToManga(this CreateMangaDto dto)
        {
            return new Manga
            {
                Id = dto.Id,
                Title = dto.Title,
                Description = dto.Description,
                Thumbnail = dto.Thumbnail,
                Status = dto.Status,
                TotalChapter = dto.TotalChapter,
                Rate = dto.Rate,
                ReleaseDate = dto.ReleaseDate,
                EndDate = dto.EndDate,
                AuthorId = dto.AuthorId,
                GenreIds = dto.GenreIds ?? new List<int>()
            };
        }
    }
}