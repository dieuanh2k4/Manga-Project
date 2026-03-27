FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY ["backend/backend.csproj", "backend/"]

RUN dotnet restore "backend/backend.csproj"

COPY . .

WORKDIR "/src/backend"
RUN dotnet build "backend.csproj" -c Release -o /app/build

# Stage 2: Publish
FROM build AS publish
RUN dotnet publish "backend.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Stage 3: Runtime
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app

# Expose API ports
EXPOSE 8080
EXPOSE 8081

# Copy publish output
COPY --from=publish /app/publish .

# Entry point để chạy ứng dụng khi container khởi động
ENTRYPOINT ["dotnet", "backend.dll"]