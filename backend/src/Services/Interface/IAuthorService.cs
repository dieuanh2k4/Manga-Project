using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Dtos.Author;
using backend.src.Models;

namespace backend.src.Services.Interface
{
    public interface IAuthorService
    {
        Task<List<Authors>> GetAllAuthor();
        Task<Authors> GetAllAuthorById(int id);
        Task<string> UploadImage(IFormFile file);
        Task<Authors> CreateAuthor(CreateAuthorDto dto);
        Task<Authors> UpdateAuthor(UpdateAuthorDto dto, int id);
        Task<Authors> DeleteAuthor(int id);
    }
}