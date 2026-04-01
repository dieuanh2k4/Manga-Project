using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Dtos.Manga;
using backend.src.Models;

namespace backend.src.Services.Interface
{
    public interface IMangaService
    {
        Task<List<Manga>> GetAllManga();
        Task<Manga> GetAllMangaById(int id);
        Task<string> UploadImage(IFormFile file);
        Task<Manga> CreateManga(CreateMangaDto dto);
        Task<Manga> UpdateManga(UpdateMangaDto dto, int id);
        Task<Manga> DeleteManga(int id);
        Task<List<Manga>> Search(string query);
        Task<List<Manga>> SortByGenre(int genreId);
        Task<List<Manga>> MangaOngoing();
        Task<List<Manga>> MangaComplete();
    }
}