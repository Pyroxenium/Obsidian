# storage

## Types

### `StorageModule`

Obsidian storage module
Provides functions to save and load Lua tables to disk, useful for saving game state, player progress, or configuration data.

## Methods

### storage.setDir(path)

Override the default save directory (must end with "/").

- **path** (`string`) New save directory path

### storage.save(name, data)

Save a value to disk under `saves/<name>.dat`.

- **name** (`string`) Name of the save (without extension)
- **data** (`table`) Lua table to save (must be serializable by textutils.serialize)

- **returns** **success** (`boolean, string|nil`) if save was successful, false and error message if failed
- **returns** **error** (`string?`) Error message if save failed, nil if successful

### storage.load(name)

Load a value from disk at `saves/<name>.dat`.

- **name** (`string`) Name of the save to load (without extension)

- **returns** **data** (`table|nil, string|nil`) if load was successful, nil and error message

### storage.delete(name)

Delete a save file at `saves/<name>.dat`.

- **name** (`string`) Name of the save to delete (without extension)

- **returns** **success** (`boolean`) True if the file was deleted, false if it did not exist

### storage.list()

Returns a list of save names (without the .dat extension) in SAVE_DIR.

- **returns** **list** (`string[]`) List of save names
