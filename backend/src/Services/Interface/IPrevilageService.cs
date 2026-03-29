using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Dtos.Previlage;
using backend.src.Models;

namespace backend.src.Services.Interface
{
    public interface IPrevilageService
    {
        Task<Previlages> CreatePrevilage(CreatePrevilageDto dto);
        Task<Previlages> UpdatePrevilage(UpdatePrevilageDto dto, int id);
        Task<Previlages> DeletePrevilage(int id);
    }
}