using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace backend.Migrations
{
    /// <inheritdoc />
    public partial class FixLibrary : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Libraries_ReaderId",
                table: "Libraries");

            migrationBuilder.CreateIndex(
                name: "IX_Libraries_ReaderId",
                table: "Libraries",
                column: "ReaderId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Libraries_ReaderId",
                table: "Libraries");

            migrationBuilder.CreateIndex(
                name: "IX_Libraries_ReaderId",
                table: "Libraries",
                column: "ReaderId",
                unique: true);
        }
    }
}
