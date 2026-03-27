using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Dtos.Genre;
using backend.src.Models;

namespace backend.src.Services.Interface
{
    public interface IGenreService
    {
        Task<List<Genres>> GetAllGenre();
        Task<Genres> CreateGenre(CreateGenreDto dto);
        Task<Genres> UpdateGenre(UpdateGenreDto dto, int id);
        Task<Genres> DeleteGenre(int id);
    }
}