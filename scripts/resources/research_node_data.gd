## research_node_data.gd
## Data resource representing a single node in the research tree in FOUL WARD.
## Simulation API: all public methods callable without UI nodes present.

class_name ResearchNodeData
extends Resource

## Unique identifier for this node, e.g. "unlock_ballista". Used in prerequisite lists.
@export var node_id: String = ""
## Human-readable name shown in the research UI tab.
@export var display_name: String = ""
## Research material consumed when this node is unlocked.
@export var research_cost: int = 2
## IDs of nodes that must already be unlocked before this one becomes available.
## Empty array means no prerequisites — node is always available to research.
@export var prerequisite_ids: Array[String] = []
## Flavour and effect description shown in the research UI.
@export var description: String = ""

