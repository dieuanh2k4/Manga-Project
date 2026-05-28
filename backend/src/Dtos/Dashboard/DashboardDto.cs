using System;
using System.Collections.Generic;

namespace backend.src.Dtos.Dashboard
{
    public class DashboardDto
    {
        public decimal TotalRevenue { get; set; }
        public int ActiveReadersCount { get; set; }
        public int TotalViews { get; set; }
        public double VipConversionRate { get; set; }
        public List<RevenuePoint> RevenueHistory { get; set; } = new();
        public List<GenreViewsDto> GenreShare { get; set; } = new();
        public List<MangaRankDto> TopManga { get; set; } = new();
    }

    public class RevenuePoint
    {
        public string Date { get; set; } = string.Empty; // e.g. "25/05"
        public decimal Revenue { get; set; }
        public int VipSignups { get; set; }
    }

    public class GenreViewsDto
    {
        public string GenreName { get; set; } = string.Empty;
        public int ViewsCount { get; set; }
    }

    public class MangaRankDto
    {
        public int MangaId { get; set; }
        public string Title { get; set; } = string.Empty;
        public string AuthorName { get; set; } = string.Empty;
        public string Thumbnail { get; set; } = string.Empty;
        public int Views { get; set; }
        public double Rating { get; set; }
        public double Score { get; set; }
        public decimal EstimatedRevenue { get; set; }
    }

    public class RecentActivityDto
    {
        public string Message { get; set; } = string.Empty;
        public DateTime Timestamp { get; set; }
        public string Type { get; set; } = string.Empty; // "vip", "register"
    }
}
