using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace backend.Migrations
{
    /// <inheritdoc />
    public partial class UpdateManga1 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "YearRelease",
                table: "Manga",
                newName: "ReleaseDate");

            migrationBuilder.RenameColumn(
                name: "DatePublish",
                table: "Manga",
                newName: "EndDate");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "ReleaseDate",
                table: "Manga",
                newName: "YearRelease");

            migrationBuilder.RenameColumn(
                name: "EndDate",
                table: "Manga",
                newName: "DatePublish");
        }
    }
}
