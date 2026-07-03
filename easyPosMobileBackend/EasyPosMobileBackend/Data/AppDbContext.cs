using Microsoft.EntityFrameworkCore;

namespace EasyPosMobileBackend.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
    }

    // DbSet<TEntity> properties will be added here once scaffolded from the
    // existing MySQL database (database-first via `dotnet ef dbcontext scaffold`).
}
