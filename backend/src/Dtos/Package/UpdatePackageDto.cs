using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace backend.src.Dtos.Package
{
    public class UpdatePackageDto
    {
        public string? Title { get; set; }
        public int Price { get; set; }
        public int DurationDays { get; set; } = 30;
        public List<int> PrevilageIds { get; set; } = new();
    }
}