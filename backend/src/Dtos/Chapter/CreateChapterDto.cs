using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace backend.src.Dtos.Chapter
{
    public class CreateChapterDto
    {
        public string? ChapterNumber { get; set; }
        public int MangaId { get; set; }
        public string? Title { get; set; }
        public bool IsPremium { get; set; } 
    }
}