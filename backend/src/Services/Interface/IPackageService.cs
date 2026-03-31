using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Dtos.Package;
using backend.src.Models;

namespace backend.src.Services.Interface
{
    public interface IPackageService
    {
        Task<Packages> CreatePackage(CreatePackageDto dto);
        Task<Packages> UpdatePackage(UpdatePackageDto dto, int id);
        Task<Packages> DeletePackage(int id);
        Task<ReaderPackageDto> PurchasePackage(int packageId, int userId);
    }
}