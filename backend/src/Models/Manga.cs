using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace backend.src.Models
{
    public class Manga
    {
        public int Id { get; set; }
        public string? Title { get; set; }
        public string? Description { get; set; }
        public string? Thumbnail { get; set; }
        public string? Status { get; set; }
        public int TotalChapter { get; set; }
        public int Rate { get; set; }
        public int AuthorId { get; set; }
        public int GenreId { get; set; }
        public DateOnly YearRelease { get; set; }
        public DateOnly DatePublish { get; set; }

        public List<Chapters>? Chapters { get; set; }
        public List<Libraries>? Libraries { get; set; }
        public List<Ratings>? Ratings { get; set; }
        public List<History>? History { get; set; }
        public List<Authors>? Authors { get; set; }
        public List<Genres>? Genres { get; set; }
    }
}