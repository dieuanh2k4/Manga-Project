using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Dtos.Genre;
using backend.src.Models;

namespace backend.src.Mappers
{
    public static class GenreMapper
    {
        public static async Task<Genres> FromDtoToGenre(this CreateGenreDto dto)
        {
            return new Genres
            {
                Id = dto.Id,
                Name = dto.Name
            };
        }
    }
}