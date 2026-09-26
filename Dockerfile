# Stage 1: Runtime Base
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
USER app
WORKDIR /app
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080

# Stage 2: SDK Build & Restore
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src

# Copy solution file and project files first to maximize Docker layer caching
COPY ["src/Web/Web.csproj", "src/Web/"]
COPY ["src/ApplicationCore/ApplicationCore.csproj", "src/ApplicationCore/"]
COPY ["src/Infrastructure/Infrastructure.csproj", "src/Infrastructure/"]
COPY ["src/BlazorAdmin/BlazorAdmin.csproj", "src/BlazorAdmin/"]
COPY ["src/BlazorShared/BlazorShared.csproj", "src/BlazorShared/"]
COPY ["src/PublicApi/PublicApi.csproj", "src/PublicApi/"]
COPY ["src/eShopWeb.AppHost/eShopWeb.AppHost.csproj", "src/eShopWeb.AppHost/"]
COPY ["src/eShopWeb.AspireServiceDefaults/eShopWeb.AspireServiceDefaults.csproj", "src/eShopWeb.AspireServiceDefaults/"]

# Restore dependencies directly for Web.csproj (.NET 9 resolves dependencies across src cleanly)
RUN dotnet restore "src/Web/Web.csproj"

# Copy full application source code
COPY src/ src/
WORKDIR "/src/src/Web"

# Stage 3: Publish Application
FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "Web.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false --no-restore

# Stage 4: Final Image
FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "Web.dll"]





