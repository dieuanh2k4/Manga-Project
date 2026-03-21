using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.ConstrainedExecution;
using System.Threading.Tasks;

namespace backend.src.Models
{
    public class Ratings
    {
        public int Id { get; set; }
        public int ReaderId { get; set; }
        public int MangaId { get; set; }
        public int Score { get; set; }

        public Readers? Readers { get; set; }
        public Manga? Manga { get; set; }
    }
}