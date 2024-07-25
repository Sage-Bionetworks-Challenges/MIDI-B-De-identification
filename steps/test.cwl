#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool
label: Run the submission against the Organizers pipeline for Scoring and Reporting

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
  scoring_results:
    type: File
    outputBinding:
      glob: 'results/MIDI_1_1_Testing/pixel_validation.xlsx'

  database_created:
    type: File
    outputBinding:
      glob: 'results/MIDI_1_1_Testing/validation_results.db'

  results:
    type: File
    outputBinding:
      glob: results.json

  status:
    type: string
    outputBinding:
      glob: results.json
      outputEval: $(JSON.parse(self[0].contents)['status'])
      loadContents: true

  invalid_reasons:
    type: string
    outputBinding:
      glob: results.json
      outputEval: $(JSON.parse(self[0].contents)['errors'])
      loadContents: true
  
  scoring_results:
    type: File
    outputBinding:
      glob: 'results/MIDI_1_1_Testing/scoring_report_series.xlsx'

  discrepancy_results:
    type: File
    outputBinding:
      glob: 'results/MIDI_1_1_Testing/discrepancy_report_participant.csv'
  
  discrepancy_internal:
    type: File
    outputBinding:
      glob: 'results/MIDI_1_1_Testing/discrepancy_report_internal.csv'

  


baseCommand: ["/bin/bash", "-c"]
arguments:
  - |
    python /usr/local/bin/MIDI_validation_script/run_validation.py $(inputs.compressed_file.path) && \
    python /usr/local/bin/MIDI_validation_script/run_reports.py $(inputs.compressed_file.path)

hints:
  DockerRequirement:
    dockerPull: docker.synapse.org/syn53065762/validate_score:v12
