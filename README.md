# VitaVehicle - "Realistic" Car Physics (g-rcp2/RCP4)

# ![image](https://github.com/jreo03/g-rcp2/assets/88580430/7bc9ad0f-bc1e-4500-8712-d5b1b93193d5) (Beta - Godot 4.2.2 Version)

(GLES3 renderer in Godot 3 was used in screenshot)

# About

VitaVehicle is a raycast-based car simulator that contains algorithms to simulate the engine, transmission, and tyre slip of a vehicle. This is the second iteration of g-rcp, and it's the fourth generation of Jreo's vehicle dynamics since 2017, as well as the usage of the Blender Game Engine. This was also ported from BGE despite that it isn't even published for that software yet at this time.

This fork in particular is a heavily modified version of the engine with the eventual goal of using it as a basis to port VitaVehicle to C++ as a Godot Engine C++ Module. Modifications done and new features added include: 
* Much more in-depth use of classes.
* Implementation of several custom resources, to make stat group saving and loading possible, and wheel tuning easier.
* Added controller support (and in general, a much more robust input API for the car).
* Exposing more functions of the engine to the external API (since direct code editing will be a lot less viable when it is compiled into the engine).
* More natively integrating the editor plugin with the features/UI of the editor.
* Simplifying a lot of the mathematical calculations and other things to improve performance.
* Static typing for the entire codebase.
* Renaming a great deal of the variables and documenting the codebase to make maintenance, understanding, and external/newcomer contributions to the codebase more realistically viable.
* Ported the following content from [the original Godot 3 release on Itch.io](https://jreo.itch.io/rcp4):
  * Car: Synic EKI \[Rally\]
  * Car: Miranda Proto
  * Map: Nitrovista: Aqua Highway
* The following content is new and currently exclusive to this fork:
  * Car: Vigero ZX

# Help

## Prerequisite Knowledge:
* The Godot editor GUI and Resource system.
* The drivetrain system of a car, including differentials. 
* The suspension system of a car, including sway bars and the concept of dampening.
* Axle alignment and its effects on tyre grip.
* The functional breakdown of a transmission, including gear ratios and the clutch system.

### Optional Prerequisite Knowledge:
* Anti-lock Braking Systems.
* Variable Valve Timing.
* Turbos, Superchargers, and Forced Inductions.

## In-engine API Reference:
Class references can be looked up in the editor like any native class of the engine:

* `ViVeCar` represents a vehicle in VitaVehicle.
* `ViVeWheel` represents the wheel of a `ViVeCar`.
* `ViVeEnvironment` represents the environment in which a VitaVehicle simulation runs. 
* ...And more, in the in-editor docs! Anything added by VitaVehicle will follow the naming convention of starting with `ViVe`.

## In-engine Guides:
At a later point in time, several guides will be available with the editor plugin for doing various things such as configuring suspension, and adding new vehicles.

# Tips

* Unit Scale: 0.30592 (1 metre = 3.268828 in translation)
* When editing a `ViVeCar` node, a torque graph will be available on the bottom panel of the editor:
  * The torque graph can be used to view the torque readout of a car in-editor without loading up a simulation. 
  * It can also track stat edits in real time if `constant refresh` is enabled.
  * It can display with several different unit types, both for the power and torque graphs.
* The currently running car and its wheels will have certain stats show up in the debugger, under the Monitors tab. This allows you to record the behavior of your car in real time for debugging.
  * Several vehicles can potentially show up at once, given that they have unique names set on the `ViVeCar`.

### Credits

Models:
* Eclipse SRC by shotman_16
* Vigero ZX model by DJ Atomika

Programmers:
* Godot and all contributors to it
* Original engine written for Godot 3 by [jreo](https://github.com/jreo03)
* Godot 4 Conversion & Fix - [r0401](https://github.com/r0401)
* Godot 4.2.2 overhaul: [c08oprkiua](https://github.com/c08oprkiua)


### Current Acknowledged Issues

* In-editor plugin is unfinished.
  * Collision editor has not been re-implemented. 
  * Docs have not been re-implemented.
* Aqua Highway and the Synic EKI Rally have graphical issues due to differences in lighting between Godot 3 and Godot 4.
* Physics are being messed up every 2 seconds (exaggerating, sort of) as optimizations are tested and either work or don't.
* Not all content from the original Itch release of VitaVehicle has been ported over yet.
