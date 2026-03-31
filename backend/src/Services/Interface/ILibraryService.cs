using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Models;

namespace backend.src.Services.Interface
{
    public interface ILibraryService
    {
        Task<List<Libraries>> GetMangaInLibrary(int userId);
        Task<Libraries> AddMangaToLibrary(int mangaId, int userId);
        Task<Libraries> DeleteMangaToLibrary(int mangaId, int userId);
    }
}