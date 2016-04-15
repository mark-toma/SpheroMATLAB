# Sphero API MATLAB SDK

Control Sphero from MATLAB in m-code!

**Sphero API MATLAB SDK** is also available on MathWorks File Exchange [here](http://www.mathworks.com/matlabcentral/fileexchange/52746-sphero-api-matlab-sdk).

## Description

This project provides a few Matlab classes that can be used to control Sphero from Matlab in m-code. Check out the [Sphero website](http://www.sphero.com/sphero) for more information about Sphero, the robotic ball.

The base class, SpheroCore: 

* Provides a Matlab interface to Sphero through the Bluetooth object of the 
  Instrument Control Toolbox 
* Implements the low-level Sphero API (see attached pdf) 
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

For more information about how this code communicates with Sphero, stop by [my wiki](http://wiki.mark-toma.com/) to browse through [Sphero API Tutorial](http://wiki.mark-toma.com/view/Sphero_API_Tutorial) and [Sphero API MATLAB SDK](http://wiki.mark-toma.com/view/Sphero_API_Matlab_SDK).
