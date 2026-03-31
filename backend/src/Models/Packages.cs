using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace backend.src.Models
{
    public class Packages
    {
        public int Id { get; set; }
        public string? Title { get; set; }
        public int Price { get; set; }

        public List<Previlages> Previlages { get; set; } = new();
        public List<ReaderPackages> ReaderPackages { get; set; } = new();
    }
}