using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VendingMachine.Core.Models;
using VendingMachine.Infrastructure.Data;

namespace VendingMachine.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class PrintJobsController : ControllerBase
{
    private readonly VendingMachineDbContext _context;
    private readonly ILogger<PrintJobsController> _logger;

    public PrintJobsController(VendingMachineDbContext context, ILogger<PrintJobsController> logger)
    {
        _context = context;
        _logger = logger;
    }

    // GET: api/PrintJobs
    [HttpGet]
    public async Task<ActionResult<IEnumerable<PrintJob>>> GetPrintJobs(
        [FromQuery] PrintJobStatus? status = null,
        [FromQuery] string? customerEmail = null,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var query = _context.PrintJobs.AsQueryable();

        if (status.HasValue)
            query = query.Where(p => p.Status == status.Value);

        if (!string.IsNullOrEmpty(customerEmail))
            query = query.Where(p => p.CustomerEmail == customerEmail);

        var totalCount = await query.CountAsync();
        var printJobs = await query
            .OrderByDescending(p => p.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Include(p => p.Logs.OrderByDescending(l => l.Timestamp).Take(5))
            .ToListAsync();

        Response.Headers["X-Total-Count"] = totalCount.ToString();
        Response.Headers["X-Page"] = page.ToString();
        Response.Headers["X-Page-Size"] = pageSize.ToString();

        return Ok(printJobs);
    }

    // GET: api/PrintJobs/{id}
    [HttpGet("{id}")]
    public async Task<ActionResult<PrintJob>> GetPrintJob(Guid id)
    {
        var printJob = await _context.PrintJobs
            .Include(p => p.Logs.OrderByDescending(l => l.Timestamp))
            .FirstOrDefaultAsync(p => p.Id == id);

        if (printJob == null)
        {
            return NotFound();
        }

        return Ok(printJob);
    }

    // POST: api/PrintJobs
    [HttpPost]
    public async Task<ActionResult<PrintJob>> CreatePrintJob([FromBody] CreatePrintJobRequest request)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        var printJob = new PrintJob
        {
            Id = Guid.NewGuid(),
            Name = request.Name,
            Description = request.Description,
            FileUrl = request.FileUrl,
            FileName = request.FileName,
            FileSize = request.FileSize,
            Material = request.Material,
            Price = request.Price,
            EstimatedPrintTimeMinutes = request.EstimatedPrintTimeMinutes,
            CustomerEmail = request.CustomerEmail,
            CustomerPhone = request.CustomerPhone,
            Status = PrintJobStatus.Pending
        };

        _context.PrintJobs.Add(printJob);

        // Add initial log entry
        var log = new PrintJobLog
        {
            Id = Guid.NewGuid(),
            PrintJobId = printJob.Id,
            EventType = "Created",
            Message = "Print job created successfully",
            Timestamp = DateTime.UtcNow
        };

        _context.PrintJobLogs.Add(log);

        await _context.SaveChangesAsync();

        _logger.LogInformation("Created print job {PrintJobId} for customer {CustomerEmail}", 
            printJob.Id, printJob.CustomerEmail);

        return CreatedAtAction(nameof(GetPrintJob), new { id = printJob.Id }, printJob);
    }

    // PUT: api/PrintJobs/{id}/status
    [HttpPut("{id}/status")]
    public async Task<IActionResult> UpdatePrintJobStatus(Guid id, [FromBody] UpdateStatusRequest request)
    {
        var printJob = await _context.PrintJobs.FindAsync(id);
        if (printJob == null)
        {
            return NotFound();
        }

        var oldStatus = printJob.Status;
        printJob.Status = request.Status;

        // Update timestamps based on status
        switch (request.Status)
        {
            case PrintJobStatus.Printing:
                printJob.StartedAt = DateTime.UtcNow;
                break;
            case PrintJobStatus.Completed:
                printJob.CompletedAt = DateTime.UtcNow;
                break;
            case PrintJobStatus.Failed:
                printJob.FailedAt = DateTime.UtcNow;
                printJob.FailureReason = request.FailureReason;
                break;
        }

        if (request.ProgressPercentage.HasValue)
        {
            printJob.ProgressPercentage = request.ProgressPercentage.Value;
        }

        if (request.PrinterId != null)
        {
            printJob.PrinterId = request.PrinterId;
        }

        // Add log entry
        var log = new PrintJobLog
        {
            Id = Guid.NewGuid(),
            PrintJobId = printJob.Id,
            EventType = "StatusChanged",
            Message = $"Status changed from {oldStatus} to {request.Status}",
            Timestamp = DateTime.UtcNow,
            AdditionalData = request.FailureReason
        };

        _context.PrintJobLogs.Add(log);

        await _context.SaveChangesAsync();

        _logger.LogInformation("Updated print job {PrintJobId} status from {OldStatus} to {NewStatus}", 
            id, oldStatus, request.Status);

        return NoContent();
    }

    // DELETE: api/PrintJobs/{id}
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeletePrintJob(Guid id)
    {
        var printJob = await _context.PrintJobs.FindAsync(id);
        if (printJob == null)
        {
            return NotFound();
        }

        _context.PrintJobs.Remove(printJob);
        await _context.SaveChangesAsync();

        return NoContent();
    }
}

public class CreatePrintJobRequest
{
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string FileUrl { get; set; } = string.Empty;
    public string FileName { get; set; } = string.Empty;
    public long FileSize { get; set; }
    public string Material { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public int EstimatedPrintTimeMinutes { get; set; }
    public string CustomerEmail { get; set; } = string.Empty;
    public string? CustomerPhone { get; set; }
}

public class UpdateStatusRequest
{
    public PrintJobStatus Status { get; set; }
    public int? ProgressPercentage { get; set; }
    public string? PrinterId { get; set; }
    public string? FailureReason { get; set; }
} 