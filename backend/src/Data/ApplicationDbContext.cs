using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using backend.src.Models;
using Microsoft.EntityFrameworkCore;

namespace backend.src.Data
{
    public class ApplicationDbContext : DbContext
    {
        public DbSet<Admin> Admins { get; set; }
        public DbSet<Authors> Authors { get; set; }
        public DbSet<Chapters> Chapters { get; set; }
        public DbSet<Genres> Genres { get; set; }
        public DbSet<History> History { get; set; }
        public DbSet<Libraries> Libraries { get; set; }
        public DbSet<Manga> Manga { get; set; }
        public DbSet<Pages> Pages { get; set; }
        public DbSet<Ratings> Ratings { get; set; }
        public DbSet<Readers> Readers { get; set; }
        public DbSet<Users> Users { get; set; }

        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> dbContextOptions) : base (dbContextOptions) {}

        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder) {}

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Admin>(entity =>
            {
                entity.HasKey(a => a.Id);
                entity.Property(a => a.Id)
                    .ValueGeneratedOnAdd()
                    .IsRequired();
                entity.Property(a => a.Name)
                    .IsRequired()
                    .HasMaxLength(50)
                    .IsUnicode();
                entity.Property(a => a.Birth)
                    .HasColumnType("date")
                    .IsRequired();
                entity.Property(a => a.Gender)
                    .HasMaxLength(20)
                    .IsUnicode(false);
                entity.Property(a => a.Address)
                    .HasMaxLength(255);
                entity.Property(a => a.Phone)
                    .HasMaxLength(15)
                    .IsUnicode(false)
                    .IsRequired();
                entity.HasIndex(a => a.Phone)
                    .IsUnique();
                entity.Property(a => a.Avatar)
                    .HasMaxLength(255);
            });

            modelBuilder.Entity<Authors>(entity =>
            {
                entity.HasKey(a => a.Id);
                entity.Property(a => a.Id)
                    .ValueGeneratedOnAdd()
                    .IsRequired();
                entity.Property(a => a.FullName)
                    .IsRequired()
                    .HasMaxLength(50)
                    .IsUnicode();
            });

            modelBuilder.Entity<Chapters>(entity =>
            {
                entity.HasKey(a => a.Id);
                entity.Property(a => a.Id)
                    .ValueGeneratedOnAdd()
                    .IsRequired();
                entity.Property(a => a.ChapterNumber)
                    .IsRequired()
                    .HasMaxLength(50)
                    .IsUnicode();
                entity.Property(a => a.Title)
                    .IsRequired()
                    .HasMaxLength(1000)
                    .IsUnicode();
                entity.Property(a => a.MangaId)
                    .IsRequired();
                entity.Property(a => a.IsPremium)
                    .IsRequired();
                
                entity.HasOne(a => a.Manga)
                    .WithMany(b => b.Chapters)
                    .HasForeignKey(a => a.MangaId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            modelBuilder.Entity<Genres>(entity =>
            {
                entity.HasKey(a => a.Id);
                entity.Property(a => a.Id)
                    .ValueGeneratedOnAdd()
                    .IsRequired();
                entity.Property(a => a.Name)
                    .IsRequired()
                    .HasMaxLength(20)
                    .IsUnicode();
            });

            modelBuilder.Entity<History>(entity =>
            {
                entity.HasKey(a => a.Id);
                entity.Property(a => a.Id)
                    .ValueGeneratedOnAdd()
                    .IsRequired();
                entity.Property(a => a.LastChapterId)
                    .IsRequired();
                entity.Property(a => a.LastPageId)
                    .IsRequired();
                entity.Property(a => a.MangaId)
                    .IsRequired();
                entity.Property(a => a.ReaderId)
                    .IsRequired();
                entity.Property(a => a.IsCompleted)
                    .IsRequired();
                entity.Property(a => a.UpdateAt)
                    .IsRequired();

                entity.HasOne(a => a.Readers)
                    .WithMany(b => b.History)
                    .HasForeignKey(a => a.ReaderId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(a => a.Manga)
                    .WithMany(b => b.History)
                    .HasForeignKey(a => a.MangaId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(a => a.Chapter)
                    .WithMany(b => b.History)
                    .HasForeignKey(a => a.LastChapterId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            modelBuilder.Entity<Libraries>(entity =>
            {
                entity.HasKey(a => a.Id);
                entity.Property(a => a.Id)
                    .ValueGeneratedOnAdd()
                    .IsRequired();
                entity.Property(a => a.MangaId)
                    .IsRequired();
                entity.Property(a => a.ReaderId)
                    .IsRequired();

                entity.HasOne(a => a.Manga)
                    .WithMany(b => b.Libraries)
                    .HasForeignKey(a => a.MangaId)
                    .OnDelete(DeleteBehavior.Cascade);
                
                entity.HasOne(a => a.Readers)
                    .WithOne(b => b.Libraries)
                    .HasForeignKey<Libraries>(a => a.ReaderId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            modelBuilder.Entity<Manga>(entity =>
            {
                entity.HasKey(a => a.Id);
                entity.Property(a => a.Id)
                    .ValueGeneratedOnAdd()
                    .IsRequired();
                entity.Property(a => a.Title)
                    .IsRequired()
                    .HasMaxLength(100)
                    .IsUnicode();
                entity.Property(a => a.Description)
                    .HasMaxLength(1000)
                    .IsUnicode();
                entity.Property(a => a.Thumbnail)
                    .HasMaxLength(200);
                entity.Property(a => a.Status)
                    .HasMaxLength(200)
                    .IsRequired();
                entity.Property(a => a.Rate)
                    .IsRequired();
                entity.Property(a => a.TotalChapter)
                    .IsRequired();
                entity.Property(a => a.AuthorId)
                    .IsRequired();
                entity.Property(a => a.GenreId)
                    .IsRequired();
                entity.Property(a => a.YearRelease)
                    .IsRequired();
                entity.Property(a => a.DatePublish)
                    .IsRequired();

                entity.HasMany(a => a.Authors)
                    .WithMany(b => b.Manga)
                    .UsingEntity(j => j.ToTable("MangaAuthors"));

                entity.HasMany(a => a.Genres)
                    .WithMany(b => b.Manga)
                    .UsingEntity(j => j.ToTable("MangaGenres"));
            });

            modelBuilder.Entity<Pages>(entity =>
            {
                entity.HasKey(a => a.Id);
                entity.Property(a => a.Id)
                    .ValueGeneratedOnAdd()
                    .IsRequired();
                entity.Property(a => a.ChapterId)
                    .IsRequired();
                entity.Property(a => a.ImageUrl)
                    .IsRequired()
                    .HasMaxLength(200);

                entity.HasOne(a => a.Chapters)
                    .WithMany(b => b.Pages)
                    .HasForeignKey(a => a.ChapterId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            modelBuilder.Entity<Ratings>(entity =>
            {
                entity.HasKey(a => a.Id);
                entity.Property(a => a.Id)
                    .ValueGeneratedOnAdd()
                    .IsRequired();
                entity.Property(a => a.MangaId)
                    .IsRequired();
                entity.Property(a => a.ReaderId)
                    .IsRequired();
                entity.Property(a => a.Score)
                    .IsRequired();
                
                entity.HasOne(a => a.Readers)
                    .WithMany(b => b.Ratings)
                    .HasForeignKey(a => a.ReaderId)
                    .OnDelete(DeleteBehavior.Cascade);
                
                entity.HasOne(a => a.Manga)
                    .WithMany(b => b.Ratings)
                    .HasForeignKey(a => a.MangaId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            modelBuilder.Entity<Readers>(entity =>
            {
                entity.HasKey(a => a.Id);
                entity.Property(a => a.Id)
                    .ValueGeneratedOnAdd()
                    .IsRequired();
                entity.Property(a => a.FullName)
                    .IsRequired()
                    .HasMaxLength(50)
                    .IsUnicode();
                entity.Property(a => a.Email)
                    .IsRequired()
                    .HasMaxLength(50);
                entity.Property(a => a.Avatar)
                    .HasMaxLength(200);
                entity.Property(a => a.IsPremium)
                    .IsRequired();
                entity.Property(a => a.Birth)
                    .HasColumnType("date")
                    .IsRequired();
                entity.Property(a => a.Gender)
                    .HasMaxLength(20)
                    .IsUnicode(false);
                entity.Property(a => a.Address)
                    .HasMaxLength(255);
                entity.Property(a => a.Phone)
                    .HasMaxLength(15)
                    .IsUnicode(false)
                    .IsRequired();
                entity.Property(a => a.Avatar)
                    .HasMaxLength(255);
            });

            modelBuilder.Entity<Users>(entity =>
            {
                entity.HasKey(a => a.Id);
                entity.Property(a => a.Id)
                    .ValueGeneratedOnAdd()
                    .IsRequired();
                entity.Property(a => a.UserName)
                    .IsRequired()
                    .HasMaxLength(20)
                    .IsUnicode();
                entity.Property(a => a.Password)
                    .IsRequired()
                    .HasMaxLength(255);
                entity.Property(a => a.Role)
                    .IsRequired()
                    .HasMaxLength(20)
                    .IsUnicode();
                
                entity.HasOne(a => a.Readers)
                    .WithOne(b => b.Users)
                    .HasForeignKey<Readers>(a => a.UserId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(a => a.Admin)
                    .WithOne(b => b.Users)
                    .HasForeignKey<Admin>(a => a.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
            });
        }
    }
}