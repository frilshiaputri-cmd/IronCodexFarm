# IronCodexFarm

Airflow UI integration for IronSoul Kaitun V2 and the K5 Auto Redeem code list.

## Files

- `LOADER.lua` — small loader for the Airflow UI script.
- `IronCodexFarm.lua` — Airflow UI with separate toggles for Auto Farm, Auto Skill, K5 Auto Redeem, and Anti AFK.
- `bootstrap_v2.lua` — customized V2 bootstrap that suppresses V2 toast notifications, clears stale level-stop flags, and removes the active level-40 gates from the downloaded combat, lobby, lobby-base, and auto-skill entry scripts before compilation.

## Source separation

- Auto Farm is started from the Ironsoulkaitun V2 bootstrap.
- Auto Redeem uses the K5 code list and the K5 `CodeRE` request shape (`event = "usecode"`).
- The Auto Redeem module from Ironsoulkaitun V2 is not used.
- The Airflow UI uses the API pattern from `Airflow_UI_Starter.lua`.

## Notes

The active bootstrap and source-filter paths have been statically checked for the known level-cap guards and V2 toast call. It has not been run inside Roblox, so game-side behavior and the current Airflow library API remain unverified.
