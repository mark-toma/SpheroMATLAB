Sphero_API_Matlab_SDK

This project provides a few Matlab classes that can be used to control 
Orbotix Sphero from Matlab in m-code. 

The base class, SpheroCore:
* Provides a Matlab interface to Sphero through the Bluetooth object of the
  Instrument Control Toolbox
* Implemtnts the low-level Sphero API (see attached pdf)
* Manages Sphero's state

The interface class, SpheroInterface (inherits from SpheroCore):
* Adds application-layer functionality to SpheroCore
* Overloaded Roll method uses right-handed coordinates
* Wrappers for Roll and Configure Locator allow easy correspondence between
  Roll and Locator coordinate systems

The class, Sphero (inherits from SpheroInterface):
* Adds backwards compatibility with Yi Jui's Sphero MATLAB Interface
* Wrapper for Roll allows for use of Yi Jui's roll method among others
  http://www.mathworks.com/matlabcentral/fileexchange/48359-sphero-matlab-interface

I've included some examples and graphical user interfaces for inspiration. 
Future development including bug-fixes, feature extensions, and even 
custom-tailored examples will be heavily motivated by user comments and 
ratings!

Before you begin ...
1) Make sure Sphero is paired in your OS (take note of the display name)
2) Open Matlab
3) Add this packages folders to Matlab's search path
   * run the command "install_sphero" from this directory
   * optionally, run the command "install_sphero save" to save the new search path
     (so that you don't have to do this every time you launch Matlab)
4) See the Getting_Started example script for more





