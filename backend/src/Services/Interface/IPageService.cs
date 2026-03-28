using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Models;
using Microsoft.AspNetCore.Http;

namespace backend.src.Services.Interface
{
    public interface IPageService
    {
        Task<List<Pages>> GetAllPage(int idManga, int idChapter);
        Task<List<Pages>> AddPageToChapter(int idManga, int idChapter, List<IFormFile> files);
    }
}