using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace backend.Migrations
{
    /// <inheritdoc />
    public partial class UpdateChapter : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Coin",
                table: "Readers");

            migrationBuilder.DropColumn(
                name: "Coin",
                table: "Chapters");

            migrationBuilder.AddColumn<bool>(
                name: "IsPremium",
                table: "Readers",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.Sql(@"
                UPDATE ""Manga""
                SET ""TotalChapter"" = '0'
                WHERE ""TotalChapter"" IS NULL
                   OR btrim(""TotalChapter"") = ''
                   OR ""TotalChapter"" !~ '^[0-9]+$';
            ");

            migrationBuilder.Sql(@"
                ALTER TABLE ""Manga""
                ALTER COLUMN ""TotalChapter"" TYPE integer
                USING ""TotalChapter""::integer;
            ");

            migrationBuilder.Sql(@"
                ALTER TABLE ""Manga""
                ALTER COLUMN ""TotalChapter"" SET DEFAULT 0;
            ");

            migrationBuilder.Sql(@"
                ALTER TABLE ""Manga""
                ALTER COLUMN ""TotalChapter"" SET NOT NULL;
            ");

            migrationBuilder.AlterColumn<string>(
                name: "Title",
                table: "Chapters",
                type: "character varying(1000)",
                maxLength: 1000,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "character varying(200)",
                oldMaxLength: 200);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IsPremium",
                table: "Readers");

            migrationBuilder.AddColumn<int>(
                name: "Coin",
                table: "Readers",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AlterColumn<string>(
                name: "TotalChapter",
                table: "Manga",
                type: "text",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "integer");

            migrationBuilder.AlterColumn<string>(
                name: "Title",
                table: "Chapters",
                type: "character varying(200)",
                maxLength: 200,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "character varying(1000)",
                oldMaxLength: 1000);

            migrationBuilder.AddColumn<int>(
                name: "Coin",
                table: "Chapters",
                type: "integer",
                nullable: false,
                defaultValue: 0);
        }
    }
}
