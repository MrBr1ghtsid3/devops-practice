using System;
using System.Linq;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace HerdLog.Api;

// GET /api/herds
//
//   no token        → 401
//   token, no Vet   → basic herd list
//   token with Vet  → herd list + health-check details
//
// !! SECURITY NOTE !!
// This code READS the token but does NOT VALIDATE it (signature, issuer,
// audience, expiry). In Step 7, API Management does that validation before
// any request reaches this Function. Until then, the Function is protected
// only by its function key. Never expose this without APIM in front.
public class GetHerds
{
    private readonly ILogger<GetHerds> _logger;

    public GetHerds(ILogger<GetHerds> logger) => _logger = logger;

    [Function("GetHerds")]
    public IActionResult Run(
        [HttpTrigger(AuthorizationLevel.Function, "get", Route = "herds")] HttpRequest req)
    {
        // 1. Get the claims out of the token.
        JsonElement? claims = ReadClaims(req);
        if (claims is null)
        {
            return new UnauthorizedObjectResult(new { error = "Missing or unreadable bearer token" });
        }

        // 2. Who is it, and are they a vet?
        string name = claims.Value.TryGetProperty("name", out var n) ? n.GetString() ?? "unknown" : "unknown";
        bool isVet = HasRole(claims.Value, "Vet");

        _logger.LogInformation("GetHerds called by {Name}. Vet: {IsVet}", name, isVet);

        // 3. Vets see everything; everyone else sees the basic fields only.
        var herds = SampleData.Herds.Select(h => isVet
            ? (object)h
            : new { h.HerdId, h.HoldingNumber, h.Species, h.HeadCount });

        return new OkObjectResult(new
        {
            viewedAs = name,
            role = isVet ? "Vet" : "Farmer",
            herds
        });
    }

    // A token is three parts separated by dots: header.payload.signature.
    // The payload is base64url-encoded JSON. We decode it and read it.
    private static JsonElement? ReadClaims(HttpRequest req)
    {
        string header = req.Headers["Authorization"].ToString();
        if (!header.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
        {
            return null;
        }

        string[] parts = header["Bearer ".Length..].Trim().Split('.');
        if (parts.Length != 3)
        {
            return null;
        }

        try
        {
            // base64url → normal base64, then pad to a multiple of 4.
            string payload = parts[1].Replace('-', '+').Replace('_', '/');
            payload = payload.PadRight(payload.Length + (4 - payload.Length % 4) % 4, '=');

            string json = Encoding.UTF8.GetString(Convert.FromBase64String(payload));
            using JsonDocument doc = JsonDocument.Parse(json);
            return doc.RootElement.Clone(); // Clone so it survives the "using"
        }
        catch (Exception)
        {
            return null; // not valid base64 or not valid JSON
        }
    }

    // "roles" is a list, e.g. ["Vet"]. Farmers have no "roles" claim at all.
    private static bool HasRole(JsonElement claims, string role) =>
        claims.TryGetProperty("roles", out var roles)
        && roles.ValueKind == JsonValueKind.Array
        && roles.EnumerateArray().Any(r => r.GetString() == role);
}

// Sample data. A real system would read this from a database.
public record Herd(
    string HerdId,
    string HoldingNumber,
    string Species,
    int HeadCount,
    string LastHealthCheck,
    string TbStatus);

public static class SampleData
{
    public static readonly Herd[] Herds =
    [
        new("H-001", "12/345/6789", "Cattle", 48, "2026-08-14", "Clear"),
        new("H-002", "12/345/6789", "Sheep", 210, "2026-06-02", "Not tested"),
        new("H-003", "51/230/0001", "Cattle", 95, "2026-09-10", "Inconclusive - retest due"),
    ];
}
