# Medialog N3 Integration Desktop

Flutter desktop UI prototype for the Medialog 7 → N3.Health СЭМД workflow.

## Current scope

The current delivery is a visual prototype only. All records, names, identifiers, counters, dates, and statuses are synthetic demo data. No Medialog SQL, N3.Health, ФРМО/ФРМР, CryptoPro, certificate, or real archive integration is implemented.

## Screens

- Dashboard and operational metrics
- Preflight checks: ФРМО, ФРМР, clinician and organization УКЭП, signing-time validation, CDA validation
- Semi-automatic СЭМД queue
- Document archive: XML/CDA, PDF, signatures, original N3 responses, readable PDF reports
- Audit log
- Settings

## Run on Windows

Install Flutter stable and enable Windows desktop support. From the repository root run:

```powershell
flutter doctor
flutter create --platforms=windows .
flutter pub get
flutter run -d windows
```

## Build a versioned Windows release

Run the PowerShell script from the repository root (or pass its path from another directory):

```powershell
.\scripts\build_release.ps1
```

The script resolves the version from `pubspec.yaml`, builds `windows --release`, and copies the complete Windows runner output into:

```text
out/<version>_<yyyy-MM-dd>/
```

For example: `out/0.1.0+1_2026-11-23/`. The folder contains the executable, required DLLs/data files, and `BUILD_INFO.txt`.

Optional parameters:

```powershell
.\scripts\build_release.ps1 -Version 0.2.0 -Date 2026-12-01
.\scripts\build_release.ps1 -SkipAnalyze
```

Existing output for the same version and date is replaced. The script does not create an installer or ZIP archive; it produces a ready-to-run release folder.

## Architecture notes

See [docs/PROTOTYPE_SCOPE.md](docs/PROTOTYPE_SCOPE.md) for the agreed scope, non-goals, and planned integration boundaries.

## Safety

This prototype is not for clinical use and must not be connected to production systems. Production work requires approved N3.Health contracts, security review, and validated medical-document templates.
