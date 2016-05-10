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
    
    function s = SpheroInterface(varargin)
      % SpheroInterface  Constructs a subclass of SpheroCore
      
      s@SpheroCore(varargin{:});
      
      % optionally initialize SpheroInterface stuff here ...
      % ...
      % ...
      
    end
    
    % =====================================================================
    % === Wrapperize Superclass methods ===================================
    
    function fail = Roll(s,speed,heading,state,varargin)
      % Roll  Wrapper for Roll@SpheroCore with negated heading.
      %   By preference, this Roll function assumes a right-handed
      %   coordinate system whereas Roll@SpheroCore uses the left-handed
      %   coordinate system defined by the Sphero API.
      assert( nargin>3,...
        'Inputs ''speed'', ''heading'', and ''state'' are required.');
      assert( isnumeric(speed) && isscalar(speed) && (speed>=0) && (speed<=1),...
        'Input ''speed'' must be a numeric scalar in [0,1].');
      assert( isnumeric(heading) && isscalar(heading),...
        'Input ''heading'' must be a numeric scalar.');
      assert( ischar(state) && any(strcmp({'normal','fast','stop'},state)),...
        'Input state must be a char array in {''normal'',''fast'',''stop''}.');
      [reset_timeout_flag,answer_flag] = s.ParseVargs(varargin{:});
      
      heading = -heading;
      
      fail = Roll@SpheroCore(s,speed,heading,state,...
        reset_timeout_flag,answer_flag);
      
    end
    
    function fail = RollWithOffset(s,speed,heading,state,varargin)
      % RollWithOffset  Roll with local property heading_offset.
      %   This function is identical to Roll@SpheroCore, but incorporates
      %   the user-specified heading_offset so that Sphero rolls in the
      %   rotated coordinate frame.
      %
      % See also:
      %   ConfigureLocatorWithOffset
      assert( nargin>3,...
        'Inputs ''speed'', ''heading'', and ''state'' are required.');
      assert( isnumeric(speed) && isscalar(speed) && (speed>=0) && (speed<=1),...
        'Input ''speed'' must be a numeric scalar in [0,1].');
      assert( isnumeric(heading) && isscalar(heading),...
        'Input ''heading'' must be a numeric scalar.');
      assert( ischar(state) && any(strcmp({'normal','fast','stop'},state)),...
        'Input state must be a char array in {''normal'',''fast'',''stop''}.');
      [reset_timeout_flag,answer_flag] = s.ParseVargs(varargin{:});
      
      heading = heading + s.heading_offset;
      
      fail = s.Roll(speed,heading,state,...
        reset_timeout_flag,answer_flag);
      
    end
    
    function fail = ConfigureLocatorWithOffset(s,x,y,flag,varargin)
      % ConfigureLocatorWithOffset  Align Locator coordinates.
      %   This method is similar to ConfigureLocator@SpheroCore, but does
      %   not take yaw_tare as a parameter. Call this method to align
      %   Sphero's locator coordinates with the RollWithOffset coordinates.   
      assert( nargin>3,...
        'Inputs ''x'', ''y'', and ''flag'' are required.');
      assert( isnumeric(x) && isscalar(x) && (x>=(-2^15)) && (x<=(2^15-1)),...
        'Input ''x'' must be a numeric scalar in [%d,%d].',...
        -2^15,(2^15)-1);
      assert( isnumeric(y) && isscalar(y) && (y>=(-2^15)) && (y<=(2^15-1)),...
        'Input ''y'' must be a numeric scalar in [%d,%d].',...
        -2^15,(2^15)-1);
      assert( islogical(flag) && isscalar(flag),...
        'Input ''flag'' must be a logical scalar.');      
      [reset_timeout_flag,answer_flag] = s.ParseVargs(varargin{:});
      
      yaw_tare = -s.heading_offset;
      
      fail =  s.ConfigureLocator(x,y,yaw_tare,flag,...
        reset_timeout_flag,answer_flag);
    end
    
    %function fail = SetRawMotorValues(s,powervec,varargin)
    %end

    % END Wrapperize Superclass methods ===================================
    
    
  end
  
end