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
                YearRelease = dto.YearRelease,
                DatePublish = dto.DatePublish,
                AuthorId = dto.AuthorId,
                GenreId = dto.GenreId
            };
        }
    }
}