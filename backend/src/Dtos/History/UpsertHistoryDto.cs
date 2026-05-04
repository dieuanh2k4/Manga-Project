using System.Text.Json.Serialization;

namespace backend.src.Dtos.History
{
    public class UpsertHistoryDto
    {
        public int MangaId { get; set; }
        public int ChapterId { get; set; }

        [JsonPropertyName("pageNumber")]
        public int PageNumber { get; set; }

        public bool? IsCompleted { get; set; }
    }
}
