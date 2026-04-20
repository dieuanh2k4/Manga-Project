---
name: projectmanga-crud-endpoints
description: Generate basic CRUD endpoints for the ProjectManga backend with code placed under src, controllers in src/Controllers, service implementations in src/Services/Implement, interfaces in src/Services/Interface, and DI registration in Program.cs. Use this whenever the user asks to add or scaffold CRUD APIs for an entity.
compatibility: backend dotnet api in this repository
---

# ProjectManga CRUD Endpoints

Use this skill to implement standard CRUD endpoints for a new or existing entity in the backend.

## Required folder layout

From the backend root:

- Put all new code under `src`.
- Controller files go in `src/Controllers`.
- DTO files go in `src/Dtos/{EntityName}`.
- Service interfaces go in `src/Services/Interface`.
- Service implementations go in `src/Services/Implement`.

## Required architecture

1. Keep controllers thin.
2. Put business logic and data access in service implementation classes.
3. Inject service interfaces into controllers.
4. Register interface to implementation mappings in `Program.cs` using `AddScoped`.
5. Use async EF Core operations (`ToListAsync`, `FindAsync`, `FirstOrDefaultAsync`, `SaveChangesAsync`).

## Naming conventions

Use entity name placeholders below:

- Interface: `I{EntityName}Service`
- Service implementation: `{EntityName}Service`
- Controller: `{EntityName}Controller`
- DTOs: `Create{EntityName}Dto`, `Update{EntityName}Dto`

Endpoint route style should follow existing backend style:

- `GET api/{EntityName}/get-all-{entity-kebab}`
- `GET api/{EntityName}/get-{entity-kebab}-by-id/{id}`
- `POST api/{EntityName}/create-{entity-kebab}`
- `PUT api/{EntityName}/update-{entity-kebab}/{id}`
- `DELETE api/{EntityName}/delete-{entity-kebab}/{id}`

## Implementation steps

1. Identify the model in `src/Models` and required fields.
2. Create DTOs for create and update in `src/Dtos/{EntityName}`.
3. Add the service interface in `src/Services/Interface`.
4. Add the service implementation in `src/Services/Implement`.
5. Add the controller in `src/Controllers` inheriting `ApiControllerBase`.
6. Register DI in `Program.cs`.
7. Build and fix compile errors.

## Service interface template

```csharp
namespace backend.src.Services.Interface
{
    public interface I{EntityName}Service
    {
        Task<List<{EntityType}>> GetAll{EntityName}();
        Task<{EntityType}> Get{EntityName}ById(int id);
        Task<{EntityType}> Create{EntityName}(Create{EntityName}Dto dto);
        Task<{EntityType}> Update{EntityName}(Update{EntityName}Dto dto, int id);
        Task Delete{EntityName}(int id);
    }
}
```

## Service implementation template

```csharp
using backend.src.Data;
using backend.src.Dtos.{EntityName};
using backend.src.Exceptions;
using backend.src.Models;
using backend.src.Services.Interface;
using Microsoft.EntityFrameworkCore;

namespace backend.src.Services.Implement
{
    public class {EntityName}Service : I{EntityName}Service
    {
        private readonly ApplicationDbContext _context;

        public {EntityName}Service(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<List<{EntityType}>> GetAll{EntityName}()
        {
            return await _context.{DbSetName}.ToListAsync();
        }

        public async Task<{EntityType}> Get{EntityName}ById(int id)
        {
            var entity = await _context.{DbSetName}.FirstOrDefaultAsync(x => x.Id == id);
            if (entity == null)
            {
                throw new Result("{EntityName} not found");
            }

            return entity;
        }

        public async Task<{EntityType}> Create{EntityName}(Create{EntityName}Dto dto)
        {
            // Map DTO to entity.
            var entity = new {EntityType}
            {
                // Assign fields from dto.
            };

            await _context.{DbSetName}.AddAsync(entity);
            await _context.SaveChangesAsync();
            return entity;
        }

        public async Task<{EntityType}> Update{EntityName}(Update{EntityName}Dto dto, int id)
        {
            var entity = await _context.{DbSetName}.FindAsync(id);
            if (entity == null)
            {
                throw new Result("{EntityName} not found");
            }

            // Update only provided fields.

            await _context.SaveChangesAsync();
            return entity;
        }

        public async Task Delete{EntityName}(int id)
        {
            var entity = await _context.{DbSetName}.FindAsync(id);
            if (entity == null)
            {
                throw new Result("{EntityName} not found");
            }

            _context.{DbSetName}.Remove(entity);
            await _context.SaveChangesAsync();
        }
    }
}
```

## Controller template

```csharp
using backend.src.Dtos.{EntityName};
using backend.src.Services.Interface;
using Microsoft.AspNetCore.Mvc;

namespace backend.src.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class {EntityName}Controller : ApiControllerBase
    {
        private readonly I{EntityName}Service _service;

        public {EntityName}Controller(I{EntityName}Service service, ILogger<{EntityName}Controller> logger)
            : base(logger)
        {
            _service = service;
        }

        [HttpGet("get-all-{entity-kebab}")]
        public async Task<IActionResult> GetAll()
        {
            try
            {
                var data = await _service.GetAll{EntityName}();
                return Ok(data);
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [HttpGet("get-{entity-kebab}-by-id/{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            try
            {
                var data = await _service.Get{EntityName}ById(id);
                return Ok(data);
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [HttpPost("create-{entity-kebab}")]
        public async Task<IActionResult> Create([FromBody] Create{EntityName}Dto dto)
        {
            try
            {
                var data = await _service.Create{EntityName}(dto);
                return Ok(data);
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [HttpPut("update-{entity-kebab}/{id}")]
        public async Task<IActionResult> Update([FromBody] Update{EntityName}Dto dto, int id)
        {
            try
            {
                var data = await _service.Update{EntityName}(dto, id);
                return Ok(data);
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }

        [HttpDelete("delete-{entity-kebab}/{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            try
            {
                await _service.Delete{EntityName}(id);
                return Ok(new { message = "Delete successful" });
            }
            catch (Exception ex)
            {
                return ReturnException(ex);
            }
        }
    }
}
```

## DI registration template

In `Program.cs` add:

```csharp
builder.Services.AddScoped<I{EntityName}Service, {EntityName}Service>();
```

## Input binding rules

- Use `[FromBody]` for JSON request payloads.
- Use `[FromForm]` and `IFormFile` only when an endpoint handles file uploads.
- Keep upload logic in the service layer, not in controller data access code.

## Validation and errors

- Validate required inputs in service methods.
- Throw `Result` for business validation failures to map to a controlled API response through `ApiControllerBase`.
- Return not found errors when entity id does not exist.

## Completion checklist

Before finishing, verify all of these:

1. New files are only under `src`.
2. Controller is in `src/Controllers`.
3. Interface is in `src/Services/Interface`.
4. Implementation is in `src/Services/Implement`.
5. Controller injects interface, not implementation.
6. DI is registered in `Program.cs`.
7. `dotnet build` succeeds.

## Expected output when this skill runs

- A concise plan of files to create or update.
- Full code for DTO, interface, implementation, and controller.
- The exact `Program.cs` DI line to add.
- A short verification summary after build.
