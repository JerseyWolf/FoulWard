# Files to Upload for Session 1: Campaign Content

**Errata (single-file bundle):** The standalone file `FILES_TO_UPLOAD.md` is **not** attached for Perplexity. This manifest exists for repo maintainers; for Perplexity, its entire contents (this list and the full text of every path below) are merged into `SESSION_01_FULL_PROMPT.md` in this folder.

Listed repository paths:

1. `scripts/resources/day_config.gd` — DayConfig resource class; all tunable fields per day (~54 lines)
2. `scripts/resources/campaign_config.gd` — CampaignConfig resource class; holds array of DayConfigs (~30 lines)
3. `scripts/resources/faction_data.gd` — FactionData resource class; enemy mix weights per faction (~87 lines)
4. `scripts/resources/boss_data.gd` — BossData resource class; boss stats and phase behavior (~84 lines)
5. `scripts/resources/territory_data.gd` — TerritoryData resource class; territory ownership/bonuses (~87 lines)
6. `scripts/resources/territory_map_data.gd` — TerritoryMapData; holds array of all territories (~63 lines)
7. `resources/campaigns/campaign_main_50_days.tres` — Current 50-day campaign; upload first 100 lines only (showing structure + first few days)
8. `resources/faction_data_default_mixed.tres` — DEFAULT_MIXED faction definition (~63 lines)
9. `resources/faction_data_orc_raiders.tres` — ORC_RAIDERS faction definition (~47 lines)
10. `resources/faction_data_plague_cult.tres` — PLAGUE_CULT faction definition (~39 lines)
11. `resources/bossdata_final_boss.tres` — Final boss data (~26 lines)
12. `resources/bossdata_orc_warlord_miniboss.tres` — Orc warlord mini-boss (~21 lines)
13. `resources/bossdata_plague_cult_miniboss.tres` — Plague cult mini-boss (~26 lines)
14. `resources/territories/main_campaign_territories.tres` — 5 territory definitions (~111 lines)

Total estimated token load: ~838 lines across 14 files
