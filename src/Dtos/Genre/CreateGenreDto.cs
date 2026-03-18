using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace backend.src.Dtos.Genre
{
    public class CreateGenreDto
    {
        public int Id { get; set; }
        public string? Name { get; set; }
    }
}