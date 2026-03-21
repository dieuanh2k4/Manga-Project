using System;
using System.Collections.Generic;
using System.Linq;
using System.Reactive;
using System.Threading.Tasks;

namespace backend.src.Models
{
    public class History
    {
        public int Id { get; set; }
        public int ReaderId { get; set; }
        public int MangaId { get; set; }
        public int LastChapterId { get; set; }
        public int LastPageId { get; set; }
        public Boolean IsCompleted { get; set; } = false;
        public TimeOnly UpdateAt { get; set; }

        public Readers? Readers { get; set; }
        public Manga? Manga { get; set; }
        public Chapters? Chapter { get; set; }
    }
}