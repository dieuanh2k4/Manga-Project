using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;

namespace backend.src.Dtos.Manga
{
    public class CreateMangaDto
    {
        public int Id { get; set; }
        public string? Title { get; set; }
        public string? Description { get; set; }
        public string? Thumbnail { get; set; }
        public IFormFile? ThumbnailFile { get; set; }
        public string? Status { get; set; }
        public int TotalChapter { get; set; }
        public int Rate { get; set; }
        public int AuthorId { get; set; }
        public int GenreId { get; set; }
        public DateOnly YearRelease { get; set; }
        public DateOnly DatePublish { get; set; }
    }
}