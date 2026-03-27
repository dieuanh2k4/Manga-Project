using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Dtos.Chapter;
using backend.src.Models;

namespace backend.src.Services.Interface
{
    public interface IChapterService
    {
        Task<List<Chapters>> GetAllChapter(int idManga);
        Task<Chapters> CreateChapter(CreateChapterDto chapterDto, int idManga);
        Task<Chapters> UpdateChapter(UpdateChapterDto dto, int idManga);
        Task<Chapters> DeleteChapter(int idManga, int idChapter);
    }
}