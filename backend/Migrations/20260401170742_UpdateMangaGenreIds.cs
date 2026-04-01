using System.Collections.Generic;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace backend.Migrations
{
    /// <inheritdoc />
    public partial class UpdateMangaGenreIds : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "GenreId",
                table: "Manga");

            migrationBuilder.AddColumn<List<int>>(
                name: "GenreIds",
                table: "Manga",
                type: "integer[]",
                nullable: false,
                defaultValueSql: "'{}'::integer[]");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "GenreIds",
                table: "Manga");

            migrationBuilder.AddColumn<int>(
                name: "GenreId",
                table: "Manga",
                type: "integer",
                nullable: false,
                defaultValue: 0);
        }
    }
}
