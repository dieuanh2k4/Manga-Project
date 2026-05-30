using backend.src.Configurations;
using backend.src.Models;
using backend.src.Services.Entitlements;
using Microsoft.EntityFrameworkCore;
using Minio;
using Minio.DataModel.Args;

namespace backend.src.Data
{
    public static class E2ESeedData
    {
        public const string AdminUserName = "e2e_admin";
        public const string AdminPassword = "E2e@123456";
        public const string ReaderUserName = "e2e_reader";
        public const string ReaderPassword = "E2e@123456";
        public const string ReaderEmail = "e2e.reader@test.local";
        public const string MangaTitle = "E2E Readable Manga";
        public const string PremiumMangaTitle = "E2E Premium Manga";

        private const string AdminEmail = "e2e.admin@test.local";
        private const string AuthorName = "E2E Author";
        private const string ActionGenreName = "E2E Action";
        private const string PremiumPackageTitle = "E2E Premium 30 Days";

        private static readonly byte[] TestPngBytes = Convert.FromBase64String(
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=");

        public static async Task InitializeAsync(
            ApplicationDbContext context,
            IMinioClient minioClient,
            IConfiguration configuration)
        {
            var bucketName = GetBucketName(configuration);

            await UploadMinioFixturesAsync(minioClient, configuration);
            await SeedUsersAsync(context, bucketName);
            await SeedPrevilagesAndPackagesAsync(context);
            await SeedAuthorsGenresAndMangaAsync(context, bucketName);
            await SeedReaderStateAsync(context);
        }

        public static async Task ResetAsync(
            ApplicationDbContext context,
            IMinioClient minioClient,
            IConfiguration configuration)
        {
            await DeleteE2EDatabaseRowsAsync(context);
            await DeleteMinioFixturesAsync(minioClient, configuration);
        }

        public static Task UploadMinioFixturesAsync(
            IMinioClient minioClient,
            IConfiguration configuration)
        {
            return SeedMinioObjectsAsync(minioClient, GetBucketName(configuration));
        }

        public static Task DeleteMinioFixturesAsync(
            IMinioClient minioClient,
            IConfiguration configuration)
        {
            return DeleteE2EMinioObjectsAsync(minioClient, GetBucketName(configuration));
        }

        private static async Task SeedUsersAsync(ApplicationDbContext context, string bucketName)
        {
            var adminUser = await UpsertUserAsync(context, AdminUserName, AdminPassword, "Admin");
            var readerUser = await UpsertUserAsync(context, ReaderUserName, ReaderPassword, "Reader");

            var admin = await context.Admins.FirstOrDefaultAsync(a => a.UserId == adminUser.Id);
            if (admin == null)
            {
                context.Admins.Add(new Admin
                {
                    Name = "E2E Admin",
                    Birth = new DateOnly(1995, 1, 1),
                    Gender = "Other",
                    Email = AdminEmail,
                    Avatar = BuildStoragePath(bucketName, "e2e/avatars/admin.png"),
                    Phone = "0999000001",
                    Address = "E2E Admin Address",
                    UserId = adminUser.Id
                });
            }
            else
            {
                admin.Name = "E2E Admin";
                admin.Email = AdminEmail;
                admin.Avatar = BuildStoragePath(bucketName, "e2e/avatars/admin.png");
                admin.Phone = "0999000001";
                admin.Address = "E2E Admin Address";
            }

            var reader = await context.Readers.FirstOrDefaultAsync(r => r.UserId == readerUser.Id);
            if (reader == null)
            {
                context.Readers.Add(new Readers
                {
                    FullName = "E2E Reader",
                    Email = ReaderEmail,
                    Avatar = BuildStoragePath(bucketName, "e2e/avatars/reader.png"),
                    IsPremium = true,
                    IsCommentMuted = false,
                    IsBanned = false,
                    RegisteredAt = DateTime.UtcNow,
                    Birth = new DateOnly(2000, 1, 1),
                    Gender = "Other",
                    Phone = "0999000011",
                    Address = "E2E Reader Address",
                    UserId = readerUser.Id
                });
            }
            else
            {
                reader.FullName = "E2E Reader";
                reader.Email = ReaderEmail;
                reader.Avatar = BuildStoragePath(bucketName, "e2e/avatars/reader.png");
                reader.IsPremium = true;
                reader.IsCommentMuted = false;
                reader.IsBanned = false;
                reader.Phone = "0999000011";
                reader.Address = "E2E Reader Address";
            }

            await context.SaveChangesAsync();
        }

        private static async Task SeedPrevilagesAndPackagesAsync(ApplicationDbContext context)
        {
            var previlageContents = new[]
            {
                $"{EntitlementFeatureKeys.ReadPremium}=true",
                $"{EntitlementFeatureKeys.NoAds}=true"
            };

            foreach (var content in previlageContents)
            {
                if (!await context.Previlages.AnyAsync(p => p.Content == content))
                {
                    context.Previlages.Add(new Previlages { Content = content });
                }
            }

            await context.SaveChangesAsync();

            var readPremiumContent = previlageContents[0];
            var noAdsContent = previlageContents[1];
            var previlages = await context.Previlages
                .Where(p => p.Content == readPremiumContent || p.Content == noAdsContent)
                .ToListAsync();

            var package = await context.Packages
                .Include(p => p.Previlages)
                .FirstOrDefaultAsync(p => p.Title == PremiumPackageTitle);

            if (package == null)
            {
                context.Packages.Add(new Packages
                {
                    Title = PremiumPackageTitle,
                    Price = 0,
                    DurationDays = 30,
                    Previlages = previlages
                });
            }
            else
            {
                package.Price = 0;
                package.DurationDays = 30;
                package.Previlages = previlages;
            }

            await context.SaveChangesAsync();
        }

        private static async Task SeedAuthorsGenresAndMangaAsync(ApplicationDbContext context, string bucketName)
        {
            var author = await context.Authors.FirstOrDefaultAsync(a => a.FullName == AuthorName);
            if (author == null)
            {
                author = new Authors
                {
                    FullName = AuthorName,
                    Avatar = BuildStoragePath(bucketName, "e2e/authors/e2e-author.png"),
                    Description = "Author used only for end-to-end tests."
                };
                context.Authors.Add(author);
            }

            var genre = await context.Genres.FirstOrDefaultAsync(g => g.Name == ActionGenreName);
            if (genre == null)
            {
                genre = new Genres { Name = ActionGenreName };
                context.Genres.Add(genre);
            }

            await context.SaveChangesAsync();

            var readableManga = await UpsertMangaAsync(
                context,
                bucketName,
                MangaTitle,
                "e2e-readable-manga",
                author,
                genre,
                isPremiumChapter: false);

            var premiumManga = await UpsertMangaAsync(
                context,
                bucketName,
                PremiumMangaTitle,
                "e2e-premium-manga",
                author,
                genre,
                isPremiumChapter: true);

            await context.SaveChangesAsync();

            await UpsertChapterPagesAsync(context, bucketName, readableManga, "e2e-readable-manga", false);
            await UpsertChapterPagesAsync(context, bucketName, premiumManga, "e2e-premium-manga", true);
        }

        private static async Task SeedReaderStateAsync(ApplicationDbContext context)
        {
            var reader = await FindReaderByUserNameAsync(context, ReaderUserName);
            var manga = await context.Manga.FirstOrDefaultAsync(m => m.Title == MangaTitle);
            var package = await context.Packages.FirstOrDefaultAsync(p => p.Title == PremiumPackageTitle);

            if (reader == null || manga == null || package == null)
            {
                return;
            }

            if (!await context.Libraries.AnyAsync(l => l.ReaderId == reader.Id && l.MangaId == manga.Id))
            {
                context.Libraries.Add(new Libraries
                {
                    ReaderId = reader.Id,
                    MangaId = manga.Id
                });
            }

            var now = DateTime.UtcNow;
            var readerPackage = await context.ReaderPackages
                .FirstOrDefaultAsync(rp => rp.ReaderId == reader.Id && rp.PackageId == package.Id);

            if (readerPackage == null)
            {
                context.ReaderPackages.Add(new ReaderPackages
                {
                    ReaderId = reader.Id,
                    PackageId = package.Id,
                    PurchasedAt = now.AddDays(-1),
                    ExpiredAt = now.AddDays(29)
                });
            }
            else
            {
                readerPackage.PurchasedAt = now.AddDays(-1);
                readerPackage.ExpiredAt = now.AddDays(29);
            }

            reader.IsPremium = true;
            await context.SaveChangesAsync();
        }

        private static async Task<Users> UpsertUserAsync(
            ApplicationDbContext context,
            string userName,
            string password,
            string role)
        {
            var user = await context.Users.FirstOrDefaultAsync(u => u.UserName == userName);
            if (user == null)
            {
                user = new Users
                {
                    UserName = userName,
                    Role = role,
                    Password = PasswordHelper.HashPassword(password),
                    TokenVersion = 0
                };
                context.Users.Add(user);
            }
            else
            {
                user.Role = role;
                user.Password = PasswordHelper.HashPassword(password);
                user.TokenVersion = 0;
            }

            await context.SaveChangesAsync();
            return user;
        }

        private static async Task<Manga> UpsertMangaAsync(
            ApplicationDbContext context,
            string bucketName,
            string title,
            string slug,
            Authors author,
            Genres genre,
            bool isPremiumChapter)
        {
            var manga = await context.Manga
                .Include(m => m.Authors)
                .Include(m => m.Genres)
                .FirstOrDefaultAsync(m => m.Title == title);

            if (manga == null)
            {
                manga = new Manga
                {
                    Title = title,
                    Authors = new List<Authors>(),
                    Genres = new List<Genres>()
                };
                context.Manga.Add(manga);
            }

            manga.Description = isPremiumChapter
                ? "Premium manga used only for end-to-end tests."
                : "Readable manga used only for end-to-end tests.";
            manga.Thumbnail = BuildStoragePath(bucketName, $"e2e/manga/{slug}/cover.png");
            manga.Status = "E2E";
            manga.Rate = 5;
            manga.TotalChapter = 1;
            manga.AuthorId = author.Id;
            manga.GenreIds = new List<int> { genre.Id };
            manga.ReleaseDate = new DateOnly(2026, 1, 1);

            manga.Authors ??= new List<Authors>();
            manga.Genres ??= new List<Genres>();

            if (!manga.Authors.Any(a => a.Id == author.Id))
            {
                manga.Authors.Add(author);
            }

            if (!manga.Genres.Any(g => g.Id == genre.Id))
            {
                manga.Genres.Add(genre);
            }

            await context.SaveChangesAsync();
            return manga;
        }

        private static async Task UpsertChapterPagesAsync(
            ApplicationDbContext context,
            string bucketName,
            Manga manga,
            string slug,
            bool isPremium)
        {
            var chapter = await context.Chapters
                .FirstOrDefaultAsync(c => c.MangaId == manga.Id && c.ChapterNumber == "1");

            if (chapter == null)
            {
                chapter = new Chapters
                {
                    MangaId = manga.Id,
                    ChapterNumber = "1"
                };
                context.Chapters.Add(chapter);
            }

            chapter.Title = isPremium ? "E2E Premium Chapter 1" : "E2E Chapter 1";
            chapter.IsPremium = isPremium;
            await context.SaveChangesAsync();

            var expectedImages = new[]
            {
                BuildStoragePath(bucketName, $"e2e/manga/{slug}/chapter-1/page-001.png"),
                BuildStoragePath(bucketName, $"e2e/manga/{slug}/chapter-1/page-002.png")
            };

            var existingPages = await context.Pages
                .Where(p => p.MangaId == manga.Id && p.ChapterId == chapter.Id)
                .ToListAsync();

            foreach (var page in existingPages.Where(p => !expectedImages.Contains(p.ImageUrl)))
            {
                context.Pages.Remove(page);
            }

            foreach (var imageUrl in expectedImages)
            {
                if (!existingPages.Any(p => p.ImageUrl == imageUrl))
                {
                    context.Pages.Add(new Pages
                    {
                        MangaId = manga.Id,
                        ChapterId = chapter.Id,
                        ImageUrl = imageUrl
                    });
                }
            }

            await context.SaveChangesAsync();
        }

        private static async Task SeedMinioObjectsAsync(IMinioClient minioClient, string bucketName)
        {
            await EnsureBucketAsync(minioClient, bucketName);

            var objects = new[]
            {
                "e2e/avatars/admin.png",
                "e2e/avatars/reader.png",
                "e2e/authors/e2e-author.png",
                "e2e/manga/e2e-readable-manga/cover.png",
                "e2e/manga/e2e-readable-manga/chapter-1/page-001.png",
                "e2e/manga/e2e-readable-manga/chapter-1/page-002.png",
                "e2e/manga/e2e-premium-manga/cover.png",
                "e2e/manga/e2e-premium-manga/chapter-1/page-001.png",
                "e2e/manga/e2e-premium-manga/chapter-1/page-002.png"
            };

            foreach (var objectName in objects)
            {
                await using var stream = new MemoryStream(TestPngBytes);
                await minioClient.PutObjectAsync(
                    new PutObjectArgs()
                        .WithBucket(bucketName)
                        .WithObject(objectName)
                        .WithStreamData(stream)
                        .WithObjectSize(stream.Length)
                        .WithContentType("image/png"));
            }
        }

        private static async Task DeleteE2EMinioObjectsAsync(IMinioClient minioClient, string bucketName)
        {
            var bucketExists = await minioClient.BucketExistsAsync(
                new BucketExistsArgs().WithBucket(bucketName));
            if (!bucketExists)
            {
                return;
            }

            var objects = new[]
            {
                "e2e/avatars/admin.png",
                "e2e/avatars/reader.png",
                "e2e/authors/e2e-author.png",
                "e2e/manga/e2e-readable-manga/cover.png",
                "e2e/manga/e2e-readable-manga/chapter-1/page-001.png",
                "e2e/manga/e2e-readable-manga/chapter-1/page-002.png",
                "e2e/manga/e2e-premium-manga/cover.png",
                "e2e/manga/e2e-premium-manga/chapter-1/page-001.png",
                "e2e/manga/e2e-premium-manga/chapter-1/page-002.png"
            };

            foreach (var objectName in objects)
            {
                try
                {
                    await minioClient.RemoveObjectAsync(
                        new RemoveObjectArgs()
                            .WithBucket(bucketName)
                            .WithObject(objectName));
                }
                catch
                {
                    // Missing E2E fixtures should not block a reset.
                }
            }
        }

        private static async Task DeleteE2EDatabaseRowsAsync(ApplicationDbContext context)
        {
            var e2eUsers = await context.Users
                .Where(u => u.UserName == AdminUserName || u.UserName == ReaderUserName)
                .ToListAsync();

            var e2eManga = await context.Manga
                .Where(m => m.Title == MangaTitle || m.Title == PremiumMangaTitle)
                .ToListAsync();

            var e2eAuthor = await context.Authors
                .Where(a => a.FullName == AuthorName)
                .ToListAsync();

            var e2eGenre = await context.Genres
                .Where(g => g.Name == ActionGenreName)
                .ToListAsync();

            var e2ePackage = await context.Packages
                .Where(p => p.Title == PremiumPackageTitle)
                .ToListAsync();

            context.Users.RemoveRange(e2eUsers);
            context.Manga.RemoveRange(e2eManga);
            context.Authors.RemoveRange(e2eAuthor);
            context.Genres.RemoveRange(e2eGenre);
            context.Packages.RemoveRange(e2ePackage);

            await context.SaveChangesAsync();
        }

        private static async Task EnsureBucketAsync(IMinioClient minioClient, string bucketName)
        {
            var exists = await minioClient.BucketExistsAsync(new BucketExistsArgs().WithBucket(bucketName));
            if (!exists)
            {
                await minioClient.MakeBucketAsync(new MakeBucketArgs().WithBucket(bucketName));
            }
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

        private static string GetBucketName(IConfiguration configuration)
        {
            var configuredBucket = configuration["Minio:Bucket"] ?? configuration["Minio:BucketName"];
            return string.IsNullOrWhiteSpace(configuredBucket)
                ? "mangazone-images"
                : configuredBucket.Trim().ToLowerInvariant();
        }

        private static string BuildStoragePath(string bucketName, string objectName)
        {
            return $"{bucketName}/{objectName.TrimStart('/')}";
        }
    }
}
