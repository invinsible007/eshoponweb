# Stage 1: Runtime Base
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
USER app
WORKDIR /app
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080

# Stage 2: SDK Build & Restore
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src

# Copy solution file and project files first to maximize Docker layer caching
COPY ["eShopOnWeb.slnx", "./"]
COPY ["src/Web/Web.csproj", "src/Web/"]
COPY ["src/ApplicationCore/ApplicationCore.csproj", "src/ApplicationCore/"]
COPY ["src/Infrastructure/Infrastructure.csproj", "src/Infrastructure/"]
COPY ["src/BlazorAdmin/BlazorAdmin.csproj", "src/BlazorAdmin/"]
COPY ["src/BlazorShared/BlazorShared.csproj", "src/BlazorShared/"]

# Restore dependencies
RUN dotnet restore "eShopOnWeb.slnx"

# Copy remaining source code and build
COPY . .
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





