using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace backend.src.Models
{
    public class Genres
    {
        public int Id { get; set; }
        public string? Name { get; set; }

        public List<Manga>? Manga { get; set; }
    }
}