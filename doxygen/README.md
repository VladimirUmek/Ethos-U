# Rules for API Function documentation

This document describes how to generate Doxygen-style documentation.

## Required setup

### Windows

- Install bash shell (for example git bash for Windows)
- Install [Doxygen](https://www.doxygen.nl/download.html) (verified to work with v1.13.2)
- Install [Graphviz](http://www.graphviz.org/download/) (verified to work with v14.1.2)
- Install Java (PlantUML requires Java)
  - Check whether Java is already installed, run `java --version` from the command line
  - If not installed, download and install [prebuilt OpenJDK Binaries](https://adoptium.net/temurin/releases) (verified to work with v25.0.2)
- Download [PlantUML compiled Jar under Apache license](https://github.com/plantuml/plantuml/releases/download/v1.2026.1/plantuml-asl-1.2026.1.jar) (verified to work with v1.2026.1):
  - Optional: check [download page](https://plantuml.com/download) for latest version
  - Copy downloaded plantuml-asl-x.jar file to C:/Tools/plantuml/ (or any other directory)
  - Create plantuml.bat with content (adjust if you use different path):

    ```text
    @echo off
    java -jar C:/Tools/plantuml/plantuml-asl-1.2026.1.jar %*
    ```

  - Add path to plantuml.bat to the environment PATH

### Linux and macOS

Use your favorite package manager (apt, brew) to download and install:

- Doxygen (verified to work with v1.13.2)
- Graphviz (verified to work with v14.1.2)
- PlantUML (verified to work with v1.2026.1)

## Build documentation

To generate documentation execute `./gen_doc.sh` in a bash shell.

## Folder structure

Directory | Description
:-- | :--
.\Doxygen\ | Doxygen documentation for Ethos-U
.\Doxygen\gen_doc.sh | Script for building documentation
.\Doxygen\Doxygen_Templates\ | Additional files defining styles and appearance
.\Doxygen\general\general.dxy | Doxygen configuration for the General section
.\Doxygen\drivers\drivers.dxy | Doxygen configuration for the Drivers section
.\Doxygen\integration\integration.dxy | Doxygen configuration for the Integration section
.\Doxygen\&lt;section&gt;\src\ | Markdown sources for each section
.\Doxygen\&lt;section&gt;\src\images\ | Image assets for each section
.\Documentation\ | Documentation output folder

### Notes

- Check [additional PlantUML documentation](https://plantuml-documentation.readthedocs.io/en/latest/index.html)
