using System;
using System.Collections.Generic;

namespace backend.src.Dtos.Package
{
    public class ReaderEntitlementsDto
    {
        public int ReaderId { get; set; }
        public bool HasActivePackage { get; set; }
        public bool CanReadPremium { get; set; }
        public DateTime? PremiumAccessExpiredAt { get; set; }
        public Dictionary<string, string> Features { get; set; } = new(StringComparer.OrdinalIgnoreCase);
        public List<ReaderPackageDto> ActivePackages { get; set; } = new();
    }
}
