using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace backend.src.Dtos.Package
{
    public class ReaderPackageDto
    {
        public int PurchaseId { get; set; }
        public int PackageId { get; set; }
        public string? PackageTitle { get; set; }
        public int PackagePrice { get; set; }
        public DateTime PurchasedAt { get; set; }
        public DateTime? ExpiredAt { get; set; }
    }
}
