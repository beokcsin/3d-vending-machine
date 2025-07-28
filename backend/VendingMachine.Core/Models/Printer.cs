using System.ComponentModel.DataAnnotations;

namespace VendingMachine.Core.Models;

public class Printer
{
    public string Id { get; set; } = string.Empty;
    
    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;
    
    [Required]
    [MaxLength(500)]
    public string Description { get; set; } = string.Empty;
    
    public PrinterStatus Status { get; set; } = PrinterStatus.Offline;
    
    [MaxLength(50)]
    public string? CurrentMaterial { get; set; }
    
    public decimal? MaterialLevel { get; set; }
    
    public decimal? Temperature { get; set; }
    
    public DateTime LastSeen { get; set; } = DateTime.UtcNow;
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    public DateTime? LastMaintenance { get; set; }
    
    [MaxLength(1000)]
    public string? ErrorMessage { get; set; }
    
    // Navigation properties
    public List<PrintJob> PrintJobs { get; set; } = new();
}

public enum PrinterStatus
{
    Offline,
    Online,
    Printing,
    Paused,
    Error,
    Maintenance
} 