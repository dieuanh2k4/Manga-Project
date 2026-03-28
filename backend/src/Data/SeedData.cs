using backend.src.Configurations;
using backend.src.Models;
using Microsoft.EntityFrameworkCore;

namespace backend.src.Data
{
    public static class SeedData
    {
        public static async Task InitializeAsync(ApplicationDbContext context)
        {
            await SeedUsersAsync(context);
            await SeedAuthorsAndGenresAsync(context);
            await SeedMangaAsync(context);
            await SeedChaptersAsync(context);
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
                    Description = "Luffy and his crew search for the legendary One Piece treasure.",
                    Thumbnail = "https://example.com/manga/one-piece.jpg",
                    Status = "Ongoing",
                    Rate = 5,
                    AuthorId = authorOda.Id,
                    GenreId = genreAdventure.Id,
                    ReleaseDate = new DateOnly(1997, 7, 22),
                    Authors = new List<Authors> { authorOda },
                    Genres = new List<Genres> { genreAction, genreAdventure, genreFantasy }
                },
                new Manga
                {
                    Title = "Jujutsu Kaisen",
                    Description = "A high school student joins a secret organization of Jujutsu sorcerers.",
                    Thumbnail = "https://example.com/manga/jujutsu-kaisen.jpg",
                    Status = "Ongoing",
                    Rate = 5,
                    AuthorId = authorGege.Id,
                    GenreId = genreAction.Id,
                    ReleaseDate = new DateOnly(2018, 3, 5),
                    EndDate = new DateOnly(2024, 9, 30),
                    Authors = new List<Authors> { authorGege },
                    Genres = new List<Genres> { genreAction, genreFantasy }
                },
                new Manga
                {
                    Title = "Kaguya-sama: Love Is War",
                    Description = "Two genius students in love wage psychological battles to make the other confess first.",
                    Thumbnail = "https://example.com/manga/kaguya-sama.jpg",
                    Status = "Completed",
                    Rate = 4,
                    AuthorId = authorAka.Id,
                    GenreId = genreRomance.Id,
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
                await SeedChapterIfNotExistsAsync(context, onePiece.Id, "1", "Romance Dawn", false);
                await SeedChapterIfNotExistsAsync(context, onePiece.Id, "2", "They Call Him Straw Hat Luffy", false);
            }

            if (jujutsu != null)
            {
                await SeedChapterIfNotExistsAsync(context, jujutsu.Id, "1", "Ryomen Sukuna", false);
                await SeedChapterIfNotExistsAsync(context, jujutsu.Id, "2", "For Myself", true);
            }

            if (kaguya != null)
            {
                await SeedChapterIfNotExistsAsync(context, kaguya.Id, "1", "Miyuki Shirogane Wants to Be Confessed To", false);
            }

            var mangaList = await context.Manga.ToListAsync();
            foreach (var manga in mangaList)
            {
                manga.TotalChapter = await context.Chapters.CountAsync(c => c.MangaId == manga.Id);
            }

            await context.SaveChangesAsync();
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
