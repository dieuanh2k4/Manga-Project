using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace backend.Migrations
{
    /// <inheritdoc />
    public partial class FixPagesMangaForeignKey : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Pages_Manga_ChapterId",
                table: "Pages");

            migrationBuilder.CreateIndex(
                name: "IX_Pages_MangaId",
                table: "Pages",
                column: "MangaId");

            migrationBuilder.AddForeignKey(
                name: "FK_Pages_Manga_MangaId",
                table: "Pages",
                column: "MangaId",
                principalTable: "Manga",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Pages_Manga_MangaId",
                table: "Pages");

            migrationBuilder.DropIndex(
                name: "IX_Pages_MangaId",
                table: "Pages");

            migrationBuilder.AddForeignKey(
                name: "FK_Pages_Manga_ChapterId",
                table: "Pages",
                column: "ChapterId",
                principalTable: "Manga",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
