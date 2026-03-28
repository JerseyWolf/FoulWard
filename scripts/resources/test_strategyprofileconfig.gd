## test_strategyprofileconfig.gd
## PRE_GENERATION_VERIFICATION: Mentally ran the required checklist for this file
## (No scene access or autoload impacts, only script resources).

extends Resource
class_name TestStrategyProfileConfig

## This test file creates a sample StrategyProfileConfig for testing purposes.

## Creates a sample StrategyProfileConfig for use in tests.
func create_sample_config() -> StrategyProfileConfig:
	var config: StrategyProfileConfig = StrategyProfileConfig.new()
	
	config.profile_ids = ["BALANCED_DEFAULT", "STRATEGY_HEAVY_FIRE", "STRATEGY_GREEDY_ECON"]
	config.runs_per_profile = 2
	config.base_seed = 1000
	config.output_directory = "user://test_logs"
	config.filename_pattern = "{profile_id}_test_{seed}_runs_{runs}.csv"
	config.append_to_existing = false
	
	return config