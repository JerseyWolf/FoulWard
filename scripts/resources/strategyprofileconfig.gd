## strategyprofileconfig.gd
## PRE_GENERATION_VERIFICATION: Mentally ran the required checklist for this file
## (Resource-only, no scene access, typed exported fields, no autoload impacts).
##
## StrategyProfileConfig specifies a batch of strategy runs.
## Prompt 16 Phase 3: Enhanced SimBot batch execution with StrategyProfileConfig and parameter sweep support.

extends Resource
class_name StrategyProfileConfig

## A list of strategy profile IDs to run in batch.
## Each profile will be run for 'runs_per_profile' times, with unique seeds.
@export var profile_ids: Array[String] = []

## Number of runs to perform for each profile.
@export var runs_per_profile: int = 1

## Base seed value for the first run of each profile.
## Subsequent runs will use base_seed + (run_index * 1000).
@export var base_seed: int = 0

## CSV output directory path.
## Each profile will write to a separate file in this directory.
@export var output_directory: String = "user://simbot_logs"

## CSV filename pattern.
## Uses {profile_id} placeholder to substitute the actual profile ID.
## Default pattern: "{profile_id}_batch_{seed}_runs_{runs}.csv"
@export var filename_pattern: String = "{profile_id}_batch_{seed}_runs_{runs}.csv"

## Whether to append to existing CSV files or overwrite them.
@export var append_to_existing: bool = false

## Optional list of base seed values to use for each profile.
## If provided, this overrides the default base_seed + run_index logic.
## Each item in this array corresponds to a profile in profile_ids.
@export var custom_seeds: Array[int] = []