# ============================================================
# UEFN Shared Utilities
# Common functions and helpers used across all sub-projects
# ============================================================

using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }

# Log helper with project prefix
LogMessage<public>(Prefix : string, Message : string) : void =
    Print("[{Prefix}] {Message}")

# Clamp a float between min and max
ClampFloat<public>(Value : float, Min : float, Max : float) : float =
    if (Value < Min):
        return Min
    if (Value > Max):
        return Max
    return Value

# Format seconds into MM:SS string
FormatTime<public>(TotalSeconds : int) : string =
    var Minutes : int = TotalSeconds / 60
    var Seconds : int = TotalSeconds - (Minutes * 60)
    if (Seconds < 10):
        return "{Minutes}:0{Seconds}"
    return "{Minutes}:{Seconds}"
