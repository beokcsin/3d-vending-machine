using System.ComponentModel.DataAnnotations;

namespace VendingMachine.Core.Models;

public class PrintJob
{
    public Guid Id { get; set; }
    
    [Required]
    [MaxLength(100)]
    public string Name { get; set; } = string.Empty;
    
    [Required]
    [MaxLength(500)]
    public string Description { get; set; } = string.Empty;
    
    [Required]
    public string FileUrl { get; set; } = string.Empty;
    
    [Required]
    public string FileName { get; set; } = string.Empty;
    
    public long FileSize { get; set; }
    
    [Required]
    [MaxLength(50)]
    public string Material { get; set; } = string.Empty;
    
    public decimal Price { get; set; }
    
    public int EstimatedPrintTimeMinutes { get; set; }
    
    public PrintJobStatus Status { get; set; } = PrintJobStatus.Pending;
    
    public string? PrinterId { get; set; }
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    public DateTime? StartedAt { get; set; }
    
    public DateTime? CompletedAt { get; set; }
    
    public DateTime? FailedAt { get; set; }
    
    [MaxLength(1000)]
    public string? FailureReason { get; set; }
    
    public int ProgressPercentage { get; set; }
    
    [Required]
    [MaxLength(100)]
    public string CustomerEmail { get; set; } = string.Empty;
    
    [MaxLength(20)]
    public string? CustomerPhone { get; set; }
    
    // Navigation properties
    public List<PrintJobLog> Logs { get; set; } = new();
}

public enum PrintJobStatus
{
    Pending,
    Queued,
    Printing,
    Completed,
    Failed,
    Cancelled
} 