using Microsoft.EntityFrameworkCore;
using VendingMachine.Core.Models;

namespace VendingMachine.Infrastructure.Data;

public class VendingMachineDbContext : DbContext
{
    public VendingMachineDbContext(DbContextOptions<VendingMachineDbContext> options) : base(options)
    {
    }

    public DbSet<PrintJob> PrintJobs { get; set; }
    public DbSet<PrintJobLog> PrintJobLogs { get; set; }
    public DbSet<Printer> Printers { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // PrintJob configuration
        modelBuilder.Entity<PrintJob>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.Name).IsRequired().HasMaxLength(100);
            entity.Property(e => e.Description).IsRequired().HasMaxLength(500);
            entity.Property(e => e.FileUrl).IsRequired();
            entity.Property(e => e.FileName).IsRequired();
            entity.Property(e => e.Material).IsRequired().HasMaxLength(50);
            entity.Property(e => e.Price).HasColumnType("decimal(10,2)");
            entity.Property(e => e.Status).HasConversion<string>();
            entity.Property(e => e.CustomerEmail).IsRequired().HasMaxLength(100);
            entity.Property(e => e.CustomerPhone).HasMaxLength(20);
            entity.Property(e => e.FailureReason).HasMaxLength(1000);
            
            entity.HasIndex(e => e.Status);
            entity.HasIndex(e => e.CreatedAt);
            entity.HasIndex(e => e.CustomerEmail);
        });

        // PrintJobLog configuration
        modelBuilder.Entity<PrintJobLog>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).ValueGeneratedOnAdd();
            entity.Property(e => e.EventType).IsRequired().HasMaxLength(50);
            entity.Property(e => e.Message).IsRequired().HasMaxLength(500);
            entity.Property(e => e.AdditionalData).HasMaxLength(1000);
            
            entity.HasOne(e => e.PrintJob)
                .WithMany(p => p.Logs)
                .HasForeignKey(e => e.PrintJobId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // Printer configuration
        modelBuilder.Entity<Printer>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Id).HasMaxLength(50);
            entity.Property(e => e.Name).IsRequired().HasMaxLength(100);
            entity.Property(e => e.Description).IsRequired().HasMaxLength(500);
            entity.Property(e => e.Status).HasConversion<string>();
            entity.Property(e => e.CurrentMaterial).HasMaxLength(50);
            entity.Property(e => e.MaterialLevel).HasColumnType("decimal(5,2)");
            entity.Property(e => e.Temperature).HasColumnType("decimal(5,2)");
            entity.Property(e => e.ErrorMessage).HasMaxLength(1000);
            
            entity.HasIndex(e => e.Status);
            entity.HasIndex(e => e.LastSeen);
        });
    }
} 