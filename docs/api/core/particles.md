# particles

## Types

### `ParticleEmitter`

The particle emitter component defines how particles are spawned and their initial properties.

| Field | Type | Description |
| --- | --- | --- |
| active | `boolean` | Whether the emitter is active and should spawn particles |
| spawnRate | `number` | Number of particles to spawn per second |
| accumulator | `number` | Internal timer to track spawning intervals |
| angle | `number` | Base angle (in degrees) for particle emission |
| spread | `number` | Angle spread (in degrees) for randomizing particle emission direction |
| speedMin | `number` | Minimum initial speed of particles |
| speedMax | `number` | Maximum initial speed of particles |
| lifeMin | `number` | Minimum lifetime of particles in seconds |
| lifeMax | `number` | Maximum lifetime of particles in seconds |
| sprite | `any\|nil` | Optional sprite to use for particles |
| colors | `table\|nil` | Optional list of colors for particles to cycle through over their lifetime |
| chars | `table\|nil` | Optional list of characters for particles to cycle through over their lifetime |
| bgColors | `table\|nil` | Optional list of background blit chars for particles over their lifetime |
| z | `number` | Render layer for particles (default 1) |
| bounce | `boolean` | Whether particles should bounce off solid tiles |
| gravityScale | `number` | Multiplier for how much gravity affects the particle (0 for no gravity) |
| drag | `number` | Linear drag coefficient to slow down particles over time (0 for no drag) |

### `ParticlesModule`

The main particles module with functions to create emitters and systems.

## Methods

### particles.createEmitter(config)

Create a particle emitter instance from a config table.

- **config** (`table`) Configuration parameters for the emitter

- **returns** **emitter** (`ParticleEmitter`) The created emitter instance

### particles.load(path)

Load an emitter config from a file and create an emitter instance.

- **path** (`string`) Path to the emitter config file

- **returns** **emitter** (`ParticleEmitter|nil`) The created emitter instance, or nil if loading failed

### particles.emitterSystem(scene)

Create an emitter system for the ECS. This system will spawn particles according to the emitter's configuration.

- **scene** (`SceneInstance`) The scene to which the system will be added

- **returns** **fn** (`fun(dt:number, ids:table, components:table)`) The emitter system function to be called each update

### particles.motionSystem(scene)

Create a motion system for particles. This system applies velocity to position, gravity, drag, and optional bouncing.

- **scene** (`SceneInstance`) The scene to which the system will be added

- **returns** **fn** (`fun(dt:number, ids:table, components:table)`) The motion system function to be called each update

### particles.updateSystem(scene)

Create an update system for particles (color/char progress).

- **scene** (`SceneInstance`) The scene to which the system will be added

- **returns** **fn** (`fun(dt:number, ids:table, components:table)`) The update system function to be called each update

### particles.cleanupSystem(scene)

Create a cleanup system that destroys expired particles.

- **scene** (`SceneInstance`) The scene to which the system will be added

- **returns** **fn** (`fun(dt:number, ids:table, components:table)`) The cleanup system function to be called each update

### particles.registerAll(scene)

Register particle systems on the given scene.

- **scene** (`SceneInstance`) The scene to which the systems will be added
