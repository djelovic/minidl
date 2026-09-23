# syntax=docker/dockerfile:1

# Build stage. Pinned to the *build* platform so the SDK runs natively even when
# targeting another architecture: the publish output is portable IL (no RID is
# set), so the same /app payload is valid for every runtime image below.
FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Restore first (cached unless the project file changes).
COPY MiniDl.csproj ./
RUN dotnet restore

# Build and publish.
COPY . ./
RUN dotnet publish MiniDl.csproj -c Release -o /app

# Runtime stage. Built once per --platform target, pulling that architecture's
# base image, so `docker buildx build --platform linux/amd64,linux/arm64`
# produces a manifest list that serves both.
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
COPY --from=build /app ./

# The aspnet base image listens on 8080 by default (ASPNETCORE_HTTP_PORTS=8080).
EXPOSE 8080

# Default download roots live under /app/downloads; mount volumes to persist
# them, and mount over /app/appsettings.json to supply host configuration.
ENTRYPOINT ["dotnet", "MiniDl.dll"]
