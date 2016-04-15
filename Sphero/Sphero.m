classdef Sphero < SpheroInterface
  % Sphero  Sphero object that offers backwards compatibility.
  %   This class inherits from the new SpheroInterface (and also its
  %   ancestor, SpheroCore). The main contribution of this class is to
  %   offers backwards compatibility with Yi Jui's original Sphero MATLAB
  %   Interface (URL below) by wrapping the Roll() and ReadLocator()
  %   methods with roll() and readLocator() using the same signature.
  %
  %   http://www.mathworks.com/matlabcentral/fileexchange/48359-sphero-matlab-interface
  
  methods
    function s = Sphero()
      s@SpheroInterface();
    end
    function connectBluetooth(s)
      % connectBluetooth  Provides an interface to
      % SpheroCore/ConnectDevice()
      disp('###########################################################################');
      disp('# Connecting to Sphero...                                                 #');
      disp('# Please make sure that Sphero is on and paired with the computer         #');
      disp('###########################################################################');
      if s.ConnectDevice();
        % ConnectDevice returns its failure status
        fprintf('\n\nConnection Failed!\nPlease try again ...\n');
        return;
      end
      disp('###########################################################################');
      disp('# Connected to Sphero !                                                   #');
      disp('# Please reconnect if Sphero loses connection                             #');
      disp('###########################################################################');
      disp(' ');
    end
    
    function roll(s,H,Speed)
      % roll  Provides an interface to Roll@
      speed = round(Speed/255); % I use fractional percent [0,1]
      heading = H; % heading in degrees
      % State = uint8(255); % I think this should be 0,1,2
      s.Roll(speed,-heading,[],[],false);
    end
    
    function [x,y,dx,dy,v] = readLocator(s)
      % readLocator  Provides an interface to SpheroCore/ReadLocator()
      s.ReadLocator();
      % My method puts the data into properties instead of passing as
      % outputs
      x = s.odo(1); y = s.odo(2); dx = s.vel(1); dy = s.vel(2); v = s.sog;
    end
    
  end
  
end
