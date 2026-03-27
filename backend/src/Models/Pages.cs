using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace backend.src.Models
{
    public class Pages
    {
        public int Id { get; set; }
        public int ChapterId { get; set; }
        public string? ImageUrl { get; set; }

        public Chapters? Chapters { get; set; }
    }
}