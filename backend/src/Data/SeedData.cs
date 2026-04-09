using backend.src.Configurations;
using backend.src.Models;
using backend.src.Services.Entitlements;
using Microsoft.EntityFrameworkCore;

namespace backend.src.Data
{
    public static class SeedData
    {
        private const string PremiumPackageTitle = "Gói Premium 30 ngày";

        public static async Task InitializeAsync(ApplicationDbContext context)
        {
            await SeedUsersAsync(context);
            await SeedPrevilagesAndPackagesAsync(context);
            await SeedAuthorsAndGenresAsync(context);
            await SeedMangaAsync(context);
            await SeedChaptersAsync(context);
            await SeedPagesAsync(context);
            await SeedLibrariesAsync(context);
            await SeedReaderPackagesAsync(context);
        }

        private static async Task SeedUsersAsync(ApplicationDbContext context)
        {
            var adminUser = await context.Users.FirstOrDefaultAsync(u => u.UserName == "admin");
            if (adminUser == null)
            {
                adminUser = new Users
                {
                    UserName = "admin",
                    Password = PasswordHelper.HashPassword("admin123"),
                    Role = "Admin"
                };
                context.Users.Add(adminUser);
            }

            var readerUser1 = await context.Users.FirstOrDefaultAsync(u => u.UserName == "reader01");
            if (readerUser1 == null)
            {
                readerUser1 = new Users
                {
                    UserName = "reader01",
                    Password = PasswordHelper.HashPassword("reader123"),
                    Role = "Reader"
                };
                context.Users.Add(readerUser1);
            }

            var readerUser2 = await context.Users.FirstOrDefaultAsync(u => u.UserName == "reader02");
            if (readerUser2 == null)
            {
                readerUser2 = new Users
                {
                    UserName = "reader02",
                    Password = PasswordHelper.HashPassword("reader123"),
                    Role = "Reader"
                };
                context.Users.Add(readerUser2);
            }

            await context.SaveChangesAsync();

            var adminExists = await context.Admins.AnyAsync(a => a.UserId == adminUser!.Id);
            if (!adminExists)
            {
                context.Admins.Add(new Admin
                {
                    Name = "System Admin",
                    Birth = new DateOnly(1999, 1, 1),
                    Gender = "Male",
                    Email = "admin@manga.local",
                    Avatar = "https://example.com/avatar/admin.png",
                    Phone = "0900000001",
                    Address = "Ho Chi Minh City",
                    UserId = adminUser.Id
                });
            }

            var reader1Exists = await context.Readers.AnyAsync(r => r.UserId == readerUser1!.Id);
            if (!reader1Exists)
            {
                context.Readers.Add(new Readers
                {
                    FullName = "Nguyen Van A",
                    Email = "reader01@manga.local",
                    Avatar = "https://example.com/avatar/reader01.png",
                    IsPremium = true,
                    Birth = new DateOnly(2002, 5, 10),
                    Gender = "Male",
                    Phone = "0900000011",
                    Address = "Ha Noi",
                    UserId = readerUser1.Id
                });
            }

            var reader2Exists = await context.Readers.AnyAsync(r => r.UserId == readerUser2!.Id);
            if (!reader2Exists)
            {
                context.Readers.Add(new Readers
                {
                    FullName = "Tran Thi B",
                    Email = "reader02@manga.local",
                    Avatar = "https://example.com/avatar/reader02.png",
                    IsPremium = false,
                    Birth = new DateOnly(2003, 11, 12),
                    Gender = "Female",
                    Phone = "0900000012",
                    Address = "Da Nang",
                    UserId = readerUser2.Id
                });
            }

            await context.SaveChangesAsync();
        }

        private static async Task SeedPrevilagesAndPackagesAsync(ApplicationDbContext context)
        {
            var previlageContents = new[]
            {
                $"{EntitlementFeatureKeys.ReadPremium}=true",
                $"{EntitlementFeatureKeys.NoAds}=true",
                $"{EntitlementFeatureKeys.OfflineDownload}=true",
                $"{EntitlementFeatureKeys.DailyChapterLimit}=200",
                $"{EntitlementFeatureKeys.EarlyAccessDays}=2",
                $"{EntitlementFeatureKeys.MaxDevices}=4"
            };

            var existingPrevilageContents = await context.Previlages
                .Where(p => p.Content != null)
                .Select(p => p.Content!)
                .ToListAsync();

            var previlageContentSet = existingPrevilageContents.ToHashSet(StringComparer.OrdinalIgnoreCase);

            foreach (var content in previlageContents)
            {
                if (previlageContentSet.Contains(content))
                {
                    continue;
                }

                context.Previlages.Add(new Previlages
                {
                    Content = content
                });

                previlageContentSet.Add(content);
            }

            await context.SaveChangesAsync();

            var previlageList = await context.Previlages
                .Where(p => p.Content != null)
                .ToListAsync();

            var previlageLookup = previlageList
                .GroupBy(p => p.Content!, StringComparer.OrdinalIgnoreCase)
                .ToDictionary(g => g.Key, g => g.First(), StringComparer.OrdinalIgnoreCase);

            var packageDefinitions = new[]
            {
                new
                {
                    Title = PremiumPackageTitle,
                    Price = 39000,
                    DurationDays = 30,
                    Previlages = new[]
                    {
                        $"{EntitlementFeatureKeys.ReadPremium}=true",
                        $"{EntitlementFeatureKeys.NoAds}=true",
                        $"{EntitlementFeatureKeys.OfflineDownload}=true",
                        $"{EntitlementFeatureKeys.MaxDevices}=2"
                    }
                },
                new
                {
                    Title = "Gói VIP 90 ngày",
                    Price = 99000,
                    DurationDays = 90,
                    Previlages = new[]
                    {
                        $"{EntitlementFeatureKeys.ReadPremium}=true",
                        $"{EntitlementFeatureKeys.NoAds}=true",
                        $"{EntitlementFeatureKeys.OfflineDownload}=true",
                        $"{EntitlementFeatureKeys.DailyChapterLimit}=200",
                        $"{EntitlementFeatureKeys.EarlyAccessDays}=2",
                        $"{EntitlementFeatureKeys.MaxDevices}=4"
                    }
                }
            };

            var existingPackages = await context.Packages
                .Include(p => p.Previlages)
                .ToListAsync();

            foreach (var definition in packageDefinitions)
            {
                var packagePrevilages = definition.Previlages
                    .Where(previlageLookup.ContainsKey)
                    .Select(key => previlageLookup[key])
                    .ToList();

                var package = existingPackages
                    .FirstOrDefault(p => p.Title == definition.Title);

                if (package == null)
                {
                    context.Packages.Add(new Packages
                    {
                        Title = definition.Title,
                        Price = definition.Price,
                        DurationDays = definition.DurationDays,
                        Previlages = packagePrevilages
                    });

                    continue;
                }

                package.Price = definition.Price;
                package.DurationDays = definition.DurationDays;
                package.Previlages = packagePrevilages;
            }

            await context.SaveChangesAsync();
        }

        private static async Task SeedAuthorsAndGenresAsync(ApplicationDbContext context)
        {
            if (!await context.Authors.AnyAsync())
            {
                context.Authors.AddRange(
                    new Authors
                    {
                        FullName = "Eiichiro Oda",
                        Avatar = "https://example.com/author/oda.png",
                        Description = "Japanese manga artist, creator of One Piece."
                    },
                    new Authors
                    {
                        FullName = "Gege Akutami",
                        Avatar = "https://example.com/author/gege.png",
                        Description = "Japanese manga artist, creator of Jujutsu Kaisen."
                    },
                    new Authors
                    {
                        FullName = "Aka Akasaka",
                        Avatar = "https://example.com/author/aka.png",
                        Description = "Japanese manga writer known for Kaguya-sama."
                    }
                );
            }

            if (!await context.Genres.AnyAsync())
            {
                context.Genres.AddRange(
                    new Genres { Name = "Action" },
                    new Genres { Name = "Adventure" },
                    new Genres { Name = "Fantasy" },
                    new Genres { Name = "Romance" },
                    new Genres { Name = "School" }
                );
            }

            await context.SaveChangesAsync();
        }

        private static async Task SeedMangaAsync(ApplicationDbContext context)
        {
            if (await context.Manga.AnyAsync())
            {
                return;
            }

            var authorOda = await context.Authors.FirstAsync(a => a.FullName == "Eiichiro Oda");
            var authorGege = await context.Authors.FirstAsync(a => a.FullName == "Gege Akutami");
            var authorAka = await context.Authors.FirstAsync(a => a.FullName == "Aka Akasaka");

            var genreAction = await context.Genres.FirstAsync(g => g.Name == "Action");
            var genreAdventure = await context.Genres.FirstAsync(g => g.Name == "Adventure");
            var genreFantasy = await context.Genres.FirstAsync(g => g.Name == "Fantasy");
            var genreRomance = await context.Genres.FirstAsync(g => g.Name == "Romance");

            context.Manga.AddRange(
                new Manga
                {
                    Title = "One Piece",
                    Description = "Luffy và thủy thủ đoàn của cậu ấy đang tìm kiếm kho báu One Piece huyền thoại.",
                    Thumbnail = "https://example.com/manga/one-piece.jpg",
                    Status = "Đang tiến hành",
                    Rate = 5,
                    AuthorId = authorOda.Id,
                    GenreIds = new List<int> { genreAction.Id, genreAdventure.Id, genreFantasy.Id },
                    ReleaseDate = new DateOnly(1997, 7, 22),
                    Authors = new List<Authors> { authorOda },
                    Genres = new List<Genres> { genreAction, genreAdventure, genreFantasy }
                },
                new Manga
                {
                    Title = "Jujutsu Kaisen",
                    Description = "Một học sinh trung học gia nhập một tổ chức bí mật gồm các pháp sư Jujutsu.",
                    Thumbnail = "https://example.com/manga/jujutsu-kaisen.jpg",
                    Status = "Hoàn Thành",
                    Rate = 5,
                    AuthorId = authorGege.Id,
                    GenreIds = new List<int> { genreAction.Id, genreFantasy.Id },
                    ReleaseDate = new DateOnly(2018, 3, 5),
                    EndDate = new DateOnly(2024, 9, 30),
                    Authors = new List<Authors> { authorGege },
                    Genres = new List<Genres> { genreAction, genreFantasy }
                },
                new Manga
                {
                    Title = "Kaguya-sama: Love Is War",
                    Description = "Hai sinh viên thiên tài đang yêu nhau đã trải qua những cuộc đấu trí để xem ai sẽ tỏ tình trước.",
                    Thumbnail = "https://example.com/manga/kaguya-sama.jpg",
                    Status = "Hoàn thành",
                    Rate = 4,
                    AuthorId = authorAka.Id,
                    GenreIds = new List<int> { genreRomance.Id },
                    ReleaseDate = new DateOnly(2015, 5, 19),
                    EndDate = new DateOnly(2022, 11, 2),
                    Authors = new List<Authors> { authorAka },
                    Genres = new List<Genres> { genreRomance }
                }
            );

            await context.SaveChangesAsync();
        }

        private static async Task SeedChaptersAsync(ApplicationDbContext context)
        {
            var onePiece = await context.Manga.FirstOrDefaultAsync(m => m.Title == "One Piece");
            var jujutsu = await context.Manga.FirstOrDefaultAsync(m => m.Title == "Jujutsu Kaisen");
            var kaguya = await context.Manga.FirstOrDefaultAsync(m => m.Title == "Kaguya-sama: Love Is War");

            if (onePiece != null)
            {
                await SeedChapterIfNotExistsAsync(context, onePiece.Id, "1", "Bình Minh Lãng Mạn", false);
                await SeedChapterIfNotExistsAsync(context, onePiece.Id, "2", "Họ gọi cậu ấy là Luffy Mũ Rơm", false);
            }

            if (jujutsu != null)
            {
                await SeedChapterIfNotExistsAsync(context, jujutsu.Id, "1", "Ryomen Sukuna", false);
                await SeedChapterIfNotExistsAsync(context, jujutsu.Id, "2", "Vì chính bản thân tôi", true);
            }

            if (kaguya != null)
            {
                await SeedChapterIfNotExistsAsync(context, kaguya.Id, "1", "Miyuki Shirogane muốn được tỏ tình", false);
            }

            var mangaList = await context.Manga.ToListAsync();
            foreach (var manga in mangaList)
            {
                manga.TotalChapter = await context.Chapters.CountAsync(c => c.MangaId == manga.Id);
            }

            await context.SaveChangesAsync();
        }

        private static async Task SeedPagesAsync(ApplicationDbContext context)
        {
            var pageDefinitions = new[]
            {
                new
                {
                    MangaTitle = "One Piece",
                    ChapterNumber = "1",
                    ImageUrls = new[]
                    {
                        "https://example.com/pages/one-piece-1-1.jpg",
                        "https://example.com/pages/one-piece-1-2.jpg"
                    }
                },
                new
                {
                    MangaTitle = "One Piece",
                    ChapterNumber = "2",
                    ImageUrls = new[]
                    {
                        "https://example.com/pages/one-piece-2-1.jpg",
                        "https://example.com/pages/one-piece-2-2.jpg"
                    }
                },
                new
                {
                    MangaTitle = "Jujutsu Kaisen",
                    ChapterNumber = "1",
                    ImageUrls = new[]
                    {
                        "https://example.com/pages/jujutsu-1-1.jpg",
                        "https://example.com/pages/jujutsu-1-2.jpg"
                    }
                },
                new
                {
                    MangaTitle = "Jujutsu Kaisen",
                    ChapterNumber = "2",
                    ImageUrls = new[]
                    {
                        "https://example.com/pages/jujutsu-2-1.jpg",
                        "https://example.com/pages/jujutsu-2-2.jpg"
                    }
                },
                new
                {
                    MangaTitle = "Kaguya-sama: Love Is War",
                    ChapterNumber = "1",
                    ImageUrls = new[]
                    {
                        "https://example.com/pages/kaguya-1-1.jpg",
                        "https://example.com/pages/kaguya-1-2.jpg"
                    }
                }
            };

            foreach (var definition in pageDefinitions)
            {
                var chapter = await context.Chapters
                    .Include(c => c.Manga)
                    .FirstOrDefaultAsync(c => c.ChapterNumber == definition.ChapterNumber
                        && c.Manga != null
                        && c.Manga.Title == definition.MangaTitle);

                if (chapter == null)
                {
                    continue;
                }

                foreach (var imageUrl in definition.ImageUrls)
                {
                    await SeedPageIfNotExistsAsync(context, chapter.Id, chapter.MangaId, imageUrl);
                }
            }

            await context.SaveChangesAsync();
        }

        private static async Task SeedLibrariesAsync(ApplicationDbContext context)
        {
            var reader1 = await FindReaderByUserNameAsync(context, "reader01");
            var reader2 = await FindReaderByUserNameAsync(context, "reader02");

            var onePiece = await context.Manga.FirstOrDefaultAsync(m => m.Title == "One Piece");
            var jujutsu = await context.Manga.FirstOrDefaultAsync(m => m.Title == "Jujutsu Kaisen");
            var kaguya = await context.Manga.FirstOrDefaultAsync(m => m.Title == "Kaguya-sama: Love Is War");

            if (reader1 != null && onePiece != null)
            {
                await SeedLibraryIfNotExistsAsync(context, reader1.Id, onePiece.Id);
            }

            if (reader1 != null && jujutsu != null)
            {
                await SeedLibraryIfNotExistsAsync(context, reader1.Id, jujutsu.Id);
            }

            if (reader2 != null && kaguya != null)
            {
                await SeedLibraryIfNotExistsAsync(context, reader2.Id, kaguya.Id);
            }

            await context.SaveChangesAsync();
        }

        private static async Task SeedReaderPackagesAsync(ApplicationDbContext context)
        {
            var premiumPackage = await context.Packages
                .FirstOrDefaultAsync(p => p.Title == PremiumPackageTitle);

            if (premiumPackage == null)
            {
                return;
            }

            var reader1 = await FindReaderByUserNameAsync(context, "reader01");
            var reader2 = await FindReaderByUserNameAsync(context, "reader02");

            var now = DateTime.UtcNow;

            if (reader1 != null)
            {
                var hasActivePremium = await context.ReaderPackages
                    .AnyAsync(rp => rp.ReaderId == reader1.Id
                        && rp.PackageId == premiumPackage.Id
                        && (rp.ExpiredAt == null || rp.ExpiredAt > now));

                if (!hasActivePremium)
                {
                    var purchasedAt = now.AddDays(-2);
                    var durationDays = premiumPackage.DurationDays > 0 ? premiumPackage.DurationDays : 30;

                    context.ReaderPackages.Add(new ReaderPackages
                    {
                        ReaderId = reader1.Id,
                        PackageId = premiumPackage.Id,
                        PurchasedAt = purchasedAt,
                        ExpiredAt = purchasedAt.AddDays(durationDays)
                    });
                }

                reader1.IsPremium = true;
            }

            if (reader2 != null)
            {
                var hasActivePackage = await context.ReaderPackages
                    .AnyAsync(rp => rp.ReaderId == reader2.Id
                        && (rp.ExpiredAt == null || rp.ExpiredAt > now));

                reader2.IsPremium = hasActivePackage;
            }

            await context.SaveChangesAsync();
        }

        private static async Task SeedLibraryIfNotExistsAsync(ApplicationDbContext context, int readerId, int mangaId)
        {
            var exists = await context.Libraries.AnyAsync(l => l.ReaderId == readerId && l.MangaId == mangaId);
            if (exists)
            {
                return;
            }

            await context.Libraries.AddAsync(new Libraries
            {
                ReaderId = readerId,
                MangaId = mangaId
            });
        }

        private static async Task SeedPageIfNotExistsAsync(ApplicationDbContext context, int chapterId, int mangaId, string imageUrl)
        {
            var exists = await context.Pages
                .AnyAsync(p => p.ChapterId == chapterId && p.MangaId == mangaId && p.ImageUrl == imageUrl);

            if (exists)
            {
                return;
            }

            await context.Pages.AddAsync(new Pages
            {
                ChapterId = chapterId,
                MangaId = mangaId,
                ImageUrl = imageUrl
            });
        }

        private static async Task<Readers?> FindReaderByUserNameAsync(ApplicationDbContext context, string userName)
        {
            var user = await context.Users.FirstOrDefaultAsync(u => u.UserName == userName);
            if (user == null)
            {
                return null;
            }

            return await context.Readers.FirstOrDefaultAsync(r => r.UserId == user.Id);
        }

        private static async Task SeedChapterIfNotExistsAsync(
            ApplicationDbContext context,
            int mangaId,
            string chapterNumber,
            string title,
            bool isPremium)
        {
            var exists = await context.Chapters.AnyAsync(c => c.MangaId == mangaId && c.ChapterNumber == chapterNumber);
            if (exists)
            {
                return;
            }

            await context.Chapters.AddAsync(new Chapters
            {
                MangaId = mangaId,
                ChapterNumber = chapterNumber,
                Title = title,
                IsPremium = isPremium
            });

            await context.SaveChangesAsync();
        }
    }
}
