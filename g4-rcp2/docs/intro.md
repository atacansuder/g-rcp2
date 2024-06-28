# Hello, and welcome to VitaVehicle!
This is a raycast-based physics simulation for cars and other wheeled motor vehicles, aiming to be realistic, detailed, and highly configurable in implementation.

VitaVehicle contains the following in its current simulation set:
* A modular, Resource-class based system, allowing for easy swapping, preset saving/loading, and on-the-fly customization.
* Simulation of wheel slip/grip.
* Suspension systems.
* Simulation of (roughly) the entire drivetrain, from clutch down to suspension.
* Simulation of engine RPM based on statistics of RPM output. 
* Basic aerodynamics. 
* A customizable control scheme, including controller, keyboard, mouse, etc. support, configurable for both digital and analog inputs for pedals and steering.
* Customizable transmissions, including the ability to define your own custom transmission within a script in order to create custom behavior. 
* In-editor torque and power graphs, featuring several units of display and real-time graph updates as you edit the stats of the vehicle.


VitaVehicle does not do literal-physical calculations, instead opting for an overarching statistical approach. For example, it does not compute the physical friction between the clutch plate and flywheel on the engine, taking in the size and physical properties of the plate and flywheel. Instead, you set a value of how much friction is present between the two and it will run with that value. 

# Demo Overview

When loading up the demo in this repository, you will load up to the default scene, `world.tscn`. This contains the test area, the base car, a visual debug GUI, and a camera, all configured for you, so that you can get straight into working. 

The repo filesystem structure is, on an overarching level, as follows:
* `addons/vitavehicle_ui`: All of the editor features for VitaVehicle, including the torque graph and the in-engine guide panel.
* `MAIN`: The core parts of the engine. These should not be tampered with, and are also where any part of the engine that will be ported to C++ when the module version of VitaVehicle happens will be contained. 
* `MISC`: Things used by the VitaVehicle demo, but are not vital to VitaVehicle itself. If you want to use VitaVehicle in a project of your own, you don't need anything in this folder.
* `FONT`: Contains the fonts and licenses therein that VitaVehicle uses.

If you have any questions about VitaVehicle, or would like to contribute, we have a [Discord server](https://discord.gg/kCvNBujcfR).