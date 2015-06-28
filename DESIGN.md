# Deyan's proposal

## Language

### provides:
  A description of the profile
### dependencies:
  Ordered list of profiles to be loaded in a standard DFS traversal
### defaults:
  Default values for options, only set if no explicit value has been set at the **end** of configuration
  * If multiple --profiles are provided on the command-line, the defaults are set right-to-left (if needed).

### requires:
  Required options for this profile, set immediately during configuration.
  * If multiple --profiles are provided on the command-line, the defaults are set left-to-right (potentially overwritten).

**High-level goal**: Any entry appearing in "requires" and "defaults" should be exposed as a user-facing customization switch. Customization which is intended to never face users should reside in the "definitions" section, such as the phases and classes of processors.

## Algorithm
  The profile expansion happens inside the high-level option expansion pass, which processes options provided to the executable (command-line or server parameters).

### Profile expansion
  0. Initialize a CFG_OPTS options hash local to this profile
  1. Load profile file and parse YAML definitions
  2. DFS descent into dependencies, go to 1. for each, passing in the current CFG_OPTS
  3. Process definitions. On collisions, merge definition hashes, overwriting key values where needed
  4. Process "requires". On collisions, overwrite values.
  5. Suspend processing "defaults" by pushing them on a global DEFAULTS_OPTS
  6. Return the assembled CFG_OPTS
  
### High-level option expansion
  1. Parse options, deferring to profile expansion on --profile and --format
  2. The parsing happens left-to-right, where collisions are overwritten as appropriate
  3. Use the assembled DEFAULT_OPTS to fill in any missing option values