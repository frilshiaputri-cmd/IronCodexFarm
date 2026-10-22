# IronCodexFarm

Airflow UI integration for IronSoul Kaitun V2 and the K5 Auto Redeem code list.

## Files

- `LOADER.lua` — small loader for the Airflow UI script.
- `IronCodexFarm.lua` — Airflow UI with separate toggles for Auto Farm, Auto Skill, K5 Auto Redeem, and Anti AFK.
- `bootstrap_v2.lua` — V2 bootstrap copy with built-in Roblox toast announcements suppressed. It continues to fetch the V2 system modules from the original Ironsoulkaitun repository.

## Source separation

- Auto Farm is started from the Ironsoulkaitun V2 bootstrap.
- Auto Redeem uses the K5 code list and the K5 `CodeRE` request shape (`event = "usecode"`).
- The Auto Redeem module from Ironsoulkaitun V2 is not used.
- The Airflow UI uses the API pattern from `Airflow_UI_Starter.lua`.

## Notes

This integration has been checked for expected repository files, feature toggles, source separation, and removal of `SendNotification` calls from the local V2 bootstrap. It has not been run inside Roblox, so game-side behavior and the current Airflow library API remain unverified.
