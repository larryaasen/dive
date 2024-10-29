# Dive Widgets

## Dive Audio Meter

The Dive audio meter provides several measurements to help users monitor and adjust audio levels. Let's break down the meanings of "magnitude," "peak," and "inputpeak" in this context:

1. Magnitude:

Magnitude refers to the current, instantaneous level of the audio signal. It's a real-time representation of the audio volume at any given moment.

- It fluctuates rapidly as the audio plays, giving you a dynamic view of the audio levels.
- Typically displayed as a constantly moving bar on the meter.
- Useful for getting a general sense of how loud the audio is at any given point.

2. Peak:

Peak represents the highest audio level reached since the last reset of the meter.

- It's a "memory" of the loudest point in your audio.
- Typically displayed as a thin line or dot that stays at the highest point reached.
- Useful for identifying the loudest parts of your audio over time.
- Helps prevent audio clipping by showing if your levels ever get too high.
- Usually resets after a few seconds or when manually reset.

3. InputPeak:

InputPeak shows the highest level of the incoming audio signal before any processing or filters are applied.

- Represents the "raw" peak level of your audio input.
- Useful for identifying potential issues with your audio source before any processing.
- Helps in setting appropriate input levels.
- Can be different from the regular peak if you have filters or processing applied.

These measurements work together to give you a comprehensive view of your audio levels:

- Magnitude shows you the current levels in real-time.
- Peak helps you catch any momentary loud sounds that you might miss.
- InputPeak lets you monitor your raw input levels to ensure you're starting with good audio before any processing.

When using these in monitoring:

- Aim to keep your magnitude generally in the green to yellow range, occasionally hitting yellow for louder moments.
- Watch the peak to ensure it never hits the red (which indicates clipping).
- Use inputPeak to set your initial levels correctly before applying any filters or adjustments.
