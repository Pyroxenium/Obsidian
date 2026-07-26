# events

## Methods

### events.handle(ctx, buf, event, ox, oy)

Process one CC:Tweaked event for the given UI context.
Process one CC:Tweaked event for the given UI context.

- **ctx** (`table`) UI context (from UI.new)
- **buf** (`Buffer`) Buffer instance (unused here, kept for signature symmetry)
- **event** (`table`) { eventType, ... } (e.g. { os.pullEvent() })
- **ox** (`number`) X offset used when the context was drawn
- **oy** (`number`) Y offset used when the context was drawn

- **returns** **consumed** (`boolean`) True if the event was consumed by the UI
