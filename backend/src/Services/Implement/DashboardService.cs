using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Data;
using backend.src.Dtos.Dashboard;
using backend.src.Services.Interface;
using Microsoft.EntityFrameworkCore;

namespace backend.src.Services.Implement
{
    public class DashboardService : IDashboardService
    {
        private readonly ApplicationDbContext _context;
        private readonly IMinioStorageService _minio;

        public DashboardService(ApplicationDbContext context, IMinioStorageService minio)
        {
            _context = context;
            _minio = minio;
        }

        public async Task<DashboardDto> GetDashboardStatsAsync()
        {
            // 1. Total Revenue (Sum of associated VIP packages purchased)
            decimal totalRevenue = await _context.ReaderPackages
                .Include(rp => rp.Package)
                .SumAsync(rp => rp.Package != null ? (decimal)rp.Package.Price : 0m);

            // 2. Active Readers Count
            int activeReadersCount = await _context.Readers.CountAsync(r => !r.IsBanned);

            // 3. Total Views
            int totalViews = await _context.History.CountAsync();

            // 4. VIP Conversion Rate
            int totalReaders = await _context.Readers.CountAsync();
            int vipReaders = await _context.Readers.CountAsync(r => r.IsPremium);
            double vipConversionRate = totalReaders > 0 ? Math.Round((double)vipReaders / totalReaders * 100, 2) : 0.0;

            // 5. Revenue History (Last 30 Days)
            var startDate = DateTime.UtcNow.Date.AddDays(-29);
            var purchases = await _context.ReaderPackages
                .Include(rp => rp.Package)
                .Where(rp => rp.PurchasedAt >= startDate)
                .ToListAsync();

            var revenueHistory = new List<RevenuePoint>();
            for (int i = 29; i >= 0; i--)
            {
                var date = DateTime.UtcNow.Date.AddDays(-i);
                var dateStr = date.ToString("dd/MM");
                var dayPurchases = purchases.Where(p => p.PurchasedAt.Date == date).ToList();
                decimal dailyRevenue = dayPurchases.Sum(p => p.Package != null ? (decimal)p.Package.Price : 0m);
                int dailySignups = dayPurchases.Count;

                revenueHistory.Add(new RevenuePoint
                {
                    Date = dateStr,
                    Revenue = dailyRevenue,
                    VipSignups = dailySignups
                });
            }

            // 6. Genre Share (In-memory grouping to support PostgreSQL array mappings)
            var genres = await _context.Genres.ToListAsync();
            var history = await _context.History.ToListAsync();
            var mangas = await _context.Manga.ToListAsync();

            var mangaViews = history.GroupBy(h => h.MangaId).ToDictionary(g => g.Key, g => g.Count());
            var genreShare = new List<GenreViewsDto>();

            foreach (var genre in genres)
            {
                int views = 0;
                foreach (var manga in mangas)
                {
                    if (manga.GenreIds != null && manga.GenreIds.Contains(genre.Id))
                    {
                        if (mangaViews.TryGetValue(manga.Id, out var v))
                        {
                            views += v;
                        }
                    }
                }
                genreShare.Add(new GenreViewsDto
                {
                    GenreName = genre.Name ?? "Khác",
                    ViewsCount = views
                });
            }
            genreShare = genreShare.OrderByDescending(g => g.ViewsCount).ToList();

            // 7. Top Manga based on Score = Views * 0.7 + Rate * 0.3
            var topMangasData = await _context.Manga
                .Select(m => new
                {
                    Manga = m,
                    Views = _context.History.Count(h => h.MangaId == m.Id)
                })
                .ToListAsync();

            var topManga = new List<MangaRankDto>();
            var rawTopMangaList = topMangasData
                .Select(x =>
                {
                    double rating = x.Manga.Rate;
                    double score = x.Views * 0.7 + rating * 0.3;
                    // Estimate revenue: e.g. 1500 VND per view on average
                    decimal estRevenue = x.Views * 1500m;

                    return new MangaRankDto
                    {
                        MangaId = x.Manga.Id,
                        Title = x.Manga.Title ?? "Manga",
                        AuthorName = "Tác giả",
                        Thumbnail = x.Manga.Thumbnail ?? "",
                        Views = x.Views,
                        Rating = rating,
                        Score = Math.Round(score, 2),
                        EstimatedRevenue = estRevenue
                    };
                })
                .OrderByDescending(m => m.Score)
                .Take(5)
                .ToList();

            // Fetch Author Names
            var authorIds = rawTopMangaList
                .Select(tm => topMangasData.First(x => x.Manga.Id == tm.MangaId).Manga.AuthorId)
                .Distinct()
                .ToList();
            var authors = await _context.Authors
                .Where(a => authorIds.Contains(a.Id))
                .ToDictionaryAsync(a => a.Id, a => a.FullName);

            foreach (var tm in rawTopMangaList)
            {
                var mangaEntity = topMangasData.First(x => x.Manga.Id == tm.MangaId).Manga;
                if (authors.TryGetValue(mangaEntity.AuthorId, out var authName))
                {
                    tm.AuthorName = authName ?? "Chưa rõ";
                }

                // Resolve MinIO Thumbnail image to public URL
                if (!string.IsNullOrEmpty(tm.Thumbnail))
                {
                    try
                    {
                        tm.Thumbnail = await _minio.GetImageUrlAsync(tm.Thumbnail);
                    }
                    catch
                    {
                        // Fallback in case of MinIO storage issue
                    }
                }
            }

            return new DashboardDto
            {
                TotalRevenue = totalRevenue,
                ActiveReadersCount = activeReadersCount,
                TotalViews = totalViews,
                VipConversionRate = vipConversionRate,
                RevenueHistory = revenueHistory,
                GenreShare = genreShare,
                TopManga = rawTopMangaList
            };
        }

        public async Task<List<RecentActivityDto>> GetRecentActivitiesAsync(int limit = 20)
        {
            var activities = new List<RecentActivityDto>();

            // VIP purchases - most recent
            var vipPurchases = await _context.ReaderPackages
                .Include(rp => rp.Reader)
                .Include(rp => rp.Package)
                .OrderByDescending(rp => rp.PurchasedAt)
                .Take(limit)
                .ToListAsync();

            foreach (var rp in vipPurchases)
            {
                var readerName = rp.Reader?.FullName ?? "Một độc giả";
                var packageName = rp.Package?.Title ?? "VIP";
                activities.Add(new RecentActivityDto
                {
                    Message = $"{readerName} vừa đăng ký gói {packageName}.",
                    Timestamp = rp.PurchasedAt,
                    Type = "vip"
                });
            }

            // New reader registrations - most recent
            var newReaders = await _context.Readers
                .OrderByDescending(r => r.RegisteredAt)
                .Take(limit)
                .ToListAsync();

            foreach (var r in newReaders)
            {
                var readerName = r.FullName ?? "Một người dùng";
                activities.Add(new RecentActivityDto
                {
                    Message = $"{readerName} đã đăng ký tài khoản mới.",
                    Timestamp = r.RegisteredAt,
                    Type = "register"
                });
            }

            // Sort by most recent and return top N
            return activities
                .OrderByDescending(a => a.Timestamp)
                .Take(limit)
                .ToList();
        }
    }
}
