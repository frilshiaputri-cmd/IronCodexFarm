# IronCodexFarm

Airflow UI integration for IronSoul Kaitun V2 and the K5 Auto Redeem code list.

## Files

- `LOADER.lua` — small loader for the Airflow UI script.
- `IronCodexFarm.lua` — Airflow UI with separate toggles for Auto Farm, Auto Skill, K5 Auto Redeem, standalone Season Ticket Spin, standalone Auto Claim All, and Anti AFK.
- `systems/reward_automation.lua` — IronCodexFarm-owned reward controller. It directly uses the game's replicated reward modules and does not start, call, or depend on the IronSoulKaitun V2 bootstrap.
- `bootstrap_v2.lua` — customized live bootstrap for the `Ironsoulkaitun` V2 repository; it suppresses V2 toast notifications and keeps the IronCodexFarm UI as the control surface.
- Auto Farm OFF pauses the V2 combat loop; ON resumes it without starting a duplicate loop.
- The Auto Skill toggle is passed through to V2 native skill casting.

## Source separation

- Auto Farm is started from the Ironsoulkaitun V2 bootstrap.
- Auto Redeem uses the K5 code list and the K5 `CodeRE` request shape (`event = "usecode"`).
- Season Ticket Spin and Auto Claim All are separate from the V2 reward automation. Spin only runs in the Lobby while enabled; Claim All waits for Lobby and Level 40+, then attempts Daily Quest, Season Pass, Seven Daily, and Guidebook handlers. The current controller does not implement Daily Login or Update Log claims.
- The Auto Redeem module from Ironsoulkaitun V2 is not used.
- The Airflow UI uses the API pattern from `Airflow_UI_Starter.lua`.

## Notes

The active bootstrap and source-filter paths have been statically checked for the known level-cap guards and V2 toast call. It has not been run inside Roblox, so game-side behavior and the current Airflow library API remain unverified.
