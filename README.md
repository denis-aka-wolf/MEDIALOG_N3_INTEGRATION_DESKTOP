# Medialog N3 Integration Desktop

Windows desktop prototype for managing medical document (СЭМД) preparation and N3.Health submission workflows.

## Current scope

This repository starts with a UI-only Flutter prototype. All records and metrics are synthetic demo data. No Medialog SQL, N3.Health, ФРМО/ФРМР, CryptoPro, or certificate integration is implemented.

## Planned modules

- Dashboard and operational metrics
- Preflight checks: ФРМО, ФРМР, УКЭП, CDA validation
- Semi-automatic СЭМД queue
- Document archive with XML/PDF/signature/response artifacts
- Audit log
- Settings

## Run

Install Flutter with Windows desktop support, then:

```powershell
flutter pub get
flutter run -d windows
```
