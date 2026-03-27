using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace backend.src.Models
{
    public class Chapters
    {
        public int Id { get; set; }
        public string? ChapterNumber { get; set; }
        public int MangaId { get; set; }
        public string? Title { get; set; }
        public bool IsPremium { get; set; } = false;

        public Manga? Manga { get; set; }
        public List<Pages>? Pages { get; set; }
        public List<History>? History { get; set; }
    }
}