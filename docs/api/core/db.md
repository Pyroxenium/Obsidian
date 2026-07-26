# db

Obsidian Engine: Database Module
In-memory key-value store with collection support and optional persistence.
Writes directly to disk under its own directory (default: "db/").

## DatabaseModule

### DatabaseModule.open(name, opts)

Create or load a collection.

- **name** (`string`) Collection name (used as filename on disk)
- **opts** (`table`, optional) Optional table: { autosave = true, dir = "db/" }

- **returns** **collection** (`Collection`) instance

## Collection

### Collection:insert(record)

Insert a new record. Automatically assigns an `_id` if not present.

- **record** (`table`) New record to insert (table of key-value pairs)

- **returns** **insertedRecord** (`table`) Copy of the inserted record, including assigned _id

### Collection:insertMany(list)

Insert multiple records at once.

- **list** (`table[]`) List of records to insert

- **returns** **insertedRecords** (`table[]`) List of inserted records with assigned _id fields

### Collection:update(filter, patch)

Update all records matching `filter` with the fields in `patch`.
Patch values overwrite existing fields; other fields are untouched.

- **filter** (`table`) Filter to match records (e.g. { type = "enemy" })
- **patch** (`table`) Fields to update (e.g. { hp = 100 })

- **returns** **updatedCount** (`number`) Number of records updated

### Collection:upsert(filter, data)

Upsert: update if exists, insert if not.

- **filter** (`table`) Filter to match records (e.g. { type = "enemy" })
- **data** (`table`) Fields to update or insert (e.g. { hp = 100 })

- **returns** (`string`) "updated"|"inserted"

### Collection:delete(filter)

Delete all records matching `filter`.

- **filter** (`table`) Filter to match records (e.g. { type = "enemy" })

- **returns** **deletedCount** (`number`) Number of records deleted

### Collection:clear()

Delete all records in the collection.

- **returns** **deletedCount** (`number`) Number of records deleted

### Collection:find(filter, opts)

Return all records matching `filter` (or all records if filter is nil).

- **filter** (`table`, optional) Filter to match records (e.g. { type = "enemy" })
- **opts** (`table`, optional) Optional query options: { orderBy = "fieldName", desc = true, offset = n, limit = m }

- **returns** **results** (`table[]`) List of matching records (copies of the stored records)

### Collection:findOne(filter)

Return the first record matching `filter`, or nil.

- **filter** (`table`, optional) Filter to match records (e.g. { type = "enemy" })

- **returns** **result** (`table|nil`) Copy of the first matching record, or nil if no match

### Collection:findById(id)

Return the record with the given `_id`, or nil.

- **id** (`number`) Record ID

- **returns** **result** (`table|nil`) Copy of the matching record, or nil if no match

### Collection:count(filter)

Return the number of records matching `filter` (or total count if nil).

- **filter** (`table`, optional) Filter to match records (e.g. { type = "enemy" })

- **returns** **count** (`number`) Number of matching records

### Collection:flush()

Write the collection to disk immediately.

- **returns** **success** (`boolean`) True if flush succeeded, false if an error occurred

### Collection:drop()

Drop the collection from disk and clear in-memory data.

### Collection:disableAutosave()

Disable automatic flushing (useful for bulk ops — call flush() manually after).

### Collection:enableAutosave()

Re-enable automatic flushing.
