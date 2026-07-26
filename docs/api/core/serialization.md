# serialization

## Methods

### Serialization.pack(scene)

Serialize a scene into a plain Lua table (no I/O).

- **scene** (`SceneInstance`) The scene to serialize

- **returns** **serializedScene** (`table`) Serialized scene data

### Serialization.save(scene, path)

Save a serialized scene to disk at `path`.

- **scene** (`SceneInstance`) The scene to serialize and save
- **path** (`string`) File path to save the serialized scene (e.g. "scenes/level1.obs")

- **returns** **success** (`boolean`) True if save succeeded, false on error

### Serialization.apply(scene, data)

Apply serialized scene data into a live scene instance.

- **scene** (`table`) SceneInstance The scene to which the data will be applied
- **data** (`table`) Serialized scene data (as produced by `Serialization.pack`)
