# Scope
The aim of this project is to capture satellite signals with a hand-made antenna and make the corresponding corrections in order to visualize correct data.
NOAA-15, NOAA-18 and NOAA-19 are the tested satellites.

# Tools
The following tools are necessary for the implementation of the project:
- RTL-SDR
- Antenna 
- Gpredict program
- GNU Radio
- Matlab

# Antenna
NOAA satellites are operating in the frequency range of 137 MHz till 138 MHz, so a V dipole antenna has been built.
Some details can be found at "HARDWARE" directory.

# GNU Radio
The NOAA signal is captured by a RTL-SDR and correctly processed in a GNU Radio diagram. Signal processing is implemented in real time, receiving as a result an APT image (with doppler effect and noise). These diagrams can be found at SOFTWARE/GNU

# Doppler Effect
When the APT image has been captured and saved, the doppler effect is corrected by a linear regression in Matlab. The scripts can be found at SOFTWARE/DOPPLER directory.

# Additional Information
Further information can be found at "Documentation" where all the references and details are contained.

