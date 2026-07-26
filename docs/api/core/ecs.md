# ecs

## World

### World.new()

Create a new World instance

- **returns** (`World`) 

### World:spawn()

Spawn a new entity

- **returns** **id** (`number`) New entity ID

### World:alive(id)

Check if an entity is alive

- **id** (`number`) Entity ID

- **returns** (`boolean`) True if entity exists and is alive

### World:despawn(id)

Destroy an entity and all its components

- **id** (`number`) Entity ID

### World:entities()

Get all living entity IDs

- **returns** (`number[]`) List of entity IDs

### World:count()

Count living entities

- **returns** (`number`) Count of living entities

### World:attach(id, component, data)

Attach a component to an entity

- **id** (`number`) Entity ID
- **component** (`string`) Component type
- **data** (`any`) Component data

### World:get(id, component)

Get a component from an entity

- **id** (`number`) Entity ID
- **component** (`string`) Component type

- **returns** (`any|nil`) Component data, or nil if entity doesn't have the component

### World:has(id, component)

Check if an entity has a component

- **id** (`number`) Entity ID
- **component** (`string`) Component type

- **returns** (`boolean`) True if entity has the component, false otherwise

### World:detach(id, component)

Detach a component from an entity

- **id** (`number`) Entity ID
- **component** (`string`) Component type

### World:components(id)

Get all components attached to an entity

- **id** (`number`) Entity ID

- **returns** (`table<string, any>`) 

### World:update(id, component, fn)

Update a component (shorthand for get + modify + attach)

- **id** (`number`) Entity ID
- **component** (`string`) Component type
- **fn** (`fun(data: any): any`) Updater function

### World:select(...)

Find entities that have ALL listed components

- **...** (`string`) Component types

- **returns** (`number[]`) Entity IDs

### World:selectAny(...)

Find entities that have ANY of the listed components

- **...** (`string`) Component types

- **returns** (`number[]`) Entity IDs

### World:exclude(...)

Find entities that have NONE of the listed components

- **...** (`string`) Component types

- **returns** (`number[]`) Entity IDs

### World:first(...)

Find the first entity that matches all components

- **...** (`string`) Component types

- **returns** (`number|nil`) Entity ID

### World:each(...)

Iterate over entities with specific components

- **...** (`string`) Component types

- **returns** (`fun(): (number|nil, ...)`) Iterator that yields entity ID and component values

### World:forEach(fn, ...)

Apply a function to all entities with specific components

- **fn** (`fun(id: number, ...: any)`) Function to apply
- **...** (`string`) Component types to match

### World:countWith(...)

Count entities with specific components

- **...** (`string`) Component types

- **returns** (`number`) 

### World:types()

Get all registered component types

- **returns** (`string[]`) List of component type names

### World:countType(component)

Count instances of a component type

- **component** (`string`) Component type

- **returns** (`number`) Count of entities with this component

### World:stats()

Get statistics about the world

- **returns** (`table`) Statistics including entity count, component counts, etc.

### World:clear()

Clear all entities and components

### World:debug()

Debug print world state

## ECSModule

### ECS.createWorld()

Create a new World instance

- **returns** (`World`) 

### ECS.new()

Alias for createWorld

- **returns** (`World`) 
