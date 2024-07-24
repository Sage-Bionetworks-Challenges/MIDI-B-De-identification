#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool
label: Run the submission against the Organizers pipeline for Scoring

requirements:
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    ramMin: 16000  # Request 16GB of memory

inputs:
  compressed_file:
    type: File
    inputBinding:
      position: 1  # Ensures this input appears directly as the first argument

outputs:
  results_directory:
    type: Directory
    outputBinding:
      glob: 'results'

baseCommand: python
arguments:
  - /usr/local/bin/MIDI_validation_script/run_validation.py
  - $(inputs.compressed_file.path)

hints:
  DockerRequirement:
    dockerPull: docker.synapse.org/syn53065762/validate_score:v12
