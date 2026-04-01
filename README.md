# Obsidian Engine

Obsidian is a high-performance 2D game engine designed specifically for **CC: Tweaked**. It features a robust Entity Component System (ECS), an optimized rendering pipeline with double-buffering, and a flexible particle system.

## Features

*   **High-Performance Rendering:** Uses double-buffering and `term.blit` optimization to ensure smooth frame rates.
*   **ECS Architecture:** Decoupled logic and data for scalable game development.
*   **Asset Management:** Automatic caching and pre-processing of sprites (`.osf`), UI layouts (`.oui`), and emitters (`.ope`).
*   **Particle System:** Fully integrated ECS-based particles with support for gravity, drag, and color/character interpolation.
*   **Static/Dynamic Layering:** Optimized handling of static backgrounds versus dynamic entities.

## Project Structure

*   `src/core/`: The heart of the engine.
    *   `loader.lua`: Handles asset loading and optimization.
    *   `particles.lua`: ECS systems for particle effects.
    *   `buffer.lua`: Low-level rendering logic (Double-Buffering).
*   `assets/`: Suggested directory for your `.osf` and `.ope` files.

## Rendering Pipeline
The engine follows a strict 7-phase pipeline:
1. Clear Phase
2. Static Pass
3. Query Pass (ECS)
4. Sort Pass (Z-Indexing)
5. Entity Pass
6. UI Pass
7. Present Phase (Sync to Hardware)

## License
This project is licensed under the MIT License.
