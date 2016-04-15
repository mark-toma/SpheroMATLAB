classdef SpheroInterface < SpheroCore
  % SpheroInterface  Application interface for Sphero.
  %   This subclass of SpheroCore is used to add application layer support
  %   to interact with the basic API functionality exposed by SpheroCore.
  %
  %   One such modification includes three methods and one property to
  %   implement a right-handed planar coordinate system with simpler
  %   correspondence of Sphero's Roll and Locator coordinates.
  %
  %   The Roll method is overloaded to accept headings specified in
  %   right-handed angles in the plane (counter-clockwise positive).
  %
  %   The heading_offset property is set by users to rotate both the Roll
  %   and Locator coordinates by the same angle (virtual heading-zero).
  %
  %   The RollWithOffset method is identical to Roll, but incorporates the
  %   heading_offset.
  %
  %   The ConfigureLocatorWithOffset method is used like ConfigureLocator,
  %   but without the yaw_tare parameter. This method rotates the Locator
  %   coordinates to be aligned with the RollWithOffset coordinates.
  
  
  properties
    heading_offset = 0;
    userdata = [];
  end
  
  methods
    
    function s = SpheroInterface()
      % SpheroInterface  Constructs a subclass of SpheroCore
      
      s@SpheroCore();
      
      % optionally initialize SpheroInterface stuff here ...
      % ...
      % ...
      
    end
    
    % =====================================================================
    % === Wrapperize Superclass methods ===================================
    
    function fail = Roll(s,speed,heading,state,...
        reset_timeout_flag,answer_flag)
      % Roll  Wrapper for Roll@SpheroCore with negated heading.
      %   By preference, this Roll function assumes a right-handed
      %   coordinate system whereas Roll@SpheroCore uses the left-handed
      %   coordinate system defined by the Sphero API.
      
      if nargin < 3
        return;
      end
      if nargin < 4, state = []; end
      if nargin < 5, reset_timeout_flag = []; end
      if nargin < 6, answer_flag = []; end
      
      heading = -heading;
      
      fail = Roll@SpheroCore(s,speed,heading,state,...
        reset_timeout_flag,answer_flag);
      
    end
    
    function fail = RollWithOffset(s,speed,heading,state,...
        reset_timeout_flag,answer_flag)
      % RollWithOffset  Roll with local property heading_offset.
      %   This function is identical to Roll@SpheroCore, but incorporates
      %   the user-specified heading_offset so that Sphero rolls in the
      %   rotated coordinate frame.
      %
      % See also:
      %   ConfigureLocatorWithOffset
      
      if nargin < 3
        return;
      end
      if nargin < 4, state = []; end
      if nargin < 5, reset_timeout_flag = []; end
      if nargin < 6, answer_flag = []; end
      
      heading = heading + s.heading_offset;
      
      fail = s.Roll(speed,heading,state,...
        reset_timeout_flag,answer_flag);
      
    end
    
    function fail = ConfigureLocatorWithOffset(s,x,y,flags,...
        reset_timeout_flag,answer_flag)
      % ConfigureLocatorWithOffset  Align Locator coordinates.
      %   This method is similar to ConfigureLocator@SpheroCore, but does
      %   not take yaw_tare as a parameter. Call this method to align
      %   Sphero's locator coordinates with the RollWithOffset coordinates.   
      
      if nargin < 3
        return;
      end
      if nargin < 5
        flags = true;
      end
      if nargin < 6
        reset_timeout_flag = [];
      end
      if nargin < 7
        answer_flag = [];
      end
      
      if flags
        flags = 1;
      else
        flags = 0;
      end
      
      yaw_tare = -s.heading_offset;
      
      fail =  s.ConfigureLocator(x,y,yaw_tare,flags,...
        reset_timeout_flag,answer_flag);
    end
    
    
    % END Wrapperize Superclass methods ===================================
    
    
  end
  
end