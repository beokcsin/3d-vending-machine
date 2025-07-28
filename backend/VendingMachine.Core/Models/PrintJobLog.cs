using System.ComponentModel.DataAnnotations;

namespace VendingMachine.Core.Models;

public class PrintJobLog
{
    public Guid Id { get; set; }
    
    public Guid PrintJobId { get; set; }
    
    [Required]
    [MaxLength(50)]
    public string EventType { get; set; } = string.Empty;
    
    [Required]
    [MaxLength(500)]
    public string Message { get; set; } = string.Empty;
    
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    
    [MaxLength(1000)]
    public string? AdditionalData { get; set; }
    
    // Navigation property
    public PrintJob PrintJob { get; set; } = null!;
} 