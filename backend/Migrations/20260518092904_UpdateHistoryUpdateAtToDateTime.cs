using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace backend.Migrations
{
    /// <inheritdoc />
    public partial class UpdateHistoryUpdateAtToDateTime : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(
                "ALTER TABLE \"History\" " +
                "ALTER COLUMN \"UpdateAt\" " +
                "TYPE timestamp with time zone " +
                "USING (CURRENT_DATE + \"UpdateAt\")"
            );
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(
                "ALTER TABLE \"History\" " +
                "ALTER COLUMN \"UpdateAt\" " +
                "TYPE time without time zone " +
                "USING (\"UpdateAt\"::time)"
            );
        }
    }
}
