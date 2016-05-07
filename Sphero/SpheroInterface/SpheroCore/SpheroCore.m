classdef SpheroCore < handle & SpheroCoreConstants
  % SpheroCore Driver for Orbotix Sphero low-level API
  %   This class provides the lowest level interface to Sphero from Matlab.
  %
  %   Its intended functionality is to provide:
  %
  %   * Hardware communication with Sphero
  %   * Implementation of Sphero low-level API
  %   * Manage Sphero's state
  
  properties (Hidden)
    
    WARN_PRINT_FLAG = true;  % Set for warning command window output
    DEBUG_PRINT_FLAG = false; % Set for verbose command window output
    DEBUG_PRINT_FUNCTION_NAME_FLAG = false; % Set to print function names upon entry (only works with debug on)
    INFO_PRINT_FLAG = false;  % Set for informative command window output
    
    % reset_timeout_flag - Reset inactivity timeout when command is sent
    %   This property specifies the default behavior of all commands
    reset_timeout_flag = true;
    
    % answer_flag - Require command response when command is sent
    %   This property specifies the default behavior of most commands. When
    %   set, a command requires a synchronous response from the device. In
    %   practice, Matlab blocks while waiting for the response and allows
    %   verification that commands execute successfully.
    %
    %   Some commands such as the Ping command and all of the Get type
    %   commands are programmed here to override this property value
    %   setting so that they're always acknowledged and receive a response.
    answer_flag = true;
    
    NewPowerNotificationFcn     = []; % User-defined callback triggered when async message received
    NewLevel1DiagnosticFcn      = []; % User-defined callback triggered when async message received
    NewDataStreamingFcn         = []; % User-defined callback triggered when async message received
    NewConfigBlockContentsFcn   = []; % User-defined callback triggered when async message received
    NewPreSleepWarningFcn       = []; % User-defined callback triggered when async message received
    NewMacroMarkersFcn          = []; % User-defined callback triggered when async message received
    NewCollisionDetectedFcn     = []; % User-defined callback triggered when async message received
    NewOrbBasicMessageFcn       = []; % User-defined callback triggered when async message received
    NewSelfLevelResultFcn       = []; % User-defined callback triggered when async message received
    NewGyroAxisLimitExceededFcn = []; % User-defined callback triggered when async message received
    NewSpheroSoulDataFcn        = []; % User-defined callback triggered when async message received
    NewLevelUpFcn               = []; % User-defined callback triggered when async message received
    NewShieldDamageFcn          = []; % User-defined callback triggered when async message received
    NewXpUpdateFcn              = []; % User-defined callback triggered when async message received
    NewBoostUpdateFcn           = []; % User-defined callback triggered when async message received
    
  end
  
  properties (Dependent)
    % time_since_init - Time since constructor was called.
    %   Returns the number of seconds (in system time) since the
    %   constructor was called for this instance. This value is used to
    %   determine the time values for the first data frame of the first
    %   packet received from streaming data as well as the time values for
    %   all data getters.
    time_since_init;
  end
  
  properties (SetAccess = private)
    
    % time - Time corresponding with the most recent data element received.
    time            = nan;
    accel_raw       = nan(3,1); % Most recent raw measured acceleration vector
    gyro_raw        = nan(3,1); % Most recent raw angular velocity vector
    motor_emf_raw   = nan(2,1); % Most recent raw motor emf
    motor_pwm_raw   = nan(2,1); % Most recent raw motor pwm
    imu_rpy_filt    = nan(3,1); % Most recent vector of filtered roll-pitch-yaw values
    accel_filt      = nan(3,1); % Most recent filtered measured acceleration vector
    gyro_filt       = nan(3,1); % Most recent filtered angular velocity vector
    motor_emf_filt  = nan(2,1); % Most recent filtered motor emf
    quat            = nan(4,1); % Most recent quaternion
    odo             = nan(2,1); % Most recent planar position vector (from odometry)
    accel_one       = nan(1,1); % Most recent measured acceleration vector magnitude
    vel             = nan(2,1); % Most recent planar velocity vector
    sog             = nan;      % Most recent speed over ground
    
    network_time = struct('offset',[],'delay',[]);
    
    % version_info - Information about Sphero's firmware versioning.
    version_info = struct(...
      'RECV',-1,...
      'MDL',-1,...
      'HW',-1,...
      'MSA_ver',-1,...
      'MSA_rev',-1,...
      'BL',-1,...
      'BAS',-1,...
      'MACRO',-1);
    
    rgb = [0,1,0];
    
    rgb_user = [];
    
    % data_streaming_info - Holds streaming data state information.
    %   This information is set in a call to SetDataStreaming and used in
    %   HandleDataStreamingMessage to parse the message and compute
    %   relative sample times.
    data_streaming_info = struct(...
      'is_enabled'          ,false,...
      'time_start'          ,0,...
      'sensors'             ,{''},...
      'mask'                ,0,...
      'mask2'               ,0,...
      'num_bytes_per_frame' ,0,...
      'sample_time'         ,0,...
      'frame_rate'          ,0,...
      'frame_count'         ,0,...
      'packet_count'        ,0,...
      'num_samples'         ,0);
    
    % collision_info - Holds collision detection information.
    %   This is a structure containing state information about collision
    %   detection API as well as the most recent collision detection data.
    collision_info = struct(...
      'is_enabled'   ,false,...
      'method'       ,[],...
      'direction'    ,zeros(3,1),...
      'axis'         ,[],...
      'planar_mag'   ,zeros(2,1),...
      'speed'        ,0,...
      'timestamp'    ,0);
    
    % bluetooth_info - Holds bluetooth name and ID information.
    %   TODO
    bluetooth_info = struct(...
      'name',[],...
      'address',[],...
      'rgb',nan(1,3));
    
    % autoreconnect_info  Holds autoreconnect information.
    %   TODO
    autoreconnect_info = struct(...
      'flag',[],...
      'time',[]);
    
    % power_state_info  TODO
    %   TODO
    power_state_info = struct(...
      'rec_ver',[],...
      'power',[],...
      'batt_voltage',[],...
      'num_charges',[],...
      'time_since_charge',[]);
    
  end
  
  properties (SetAccess=private, GetAccess=private)
    
    % bt - Bluetooth object for Sphero communications.
    %   This Bluetooth object provides the hardware interface to Sphero. It
    %   must also be properly cleaned up when this object is destroyed by
    %   explictly calling |delete()| on this object. If you run into
    %   problems, you can free up Bluetooth connections by calling
    %   |delete(instrfindall)| before creating a new object.
    %
    %   See also:
    %     delete
    bt = [];
    
  end
  
  properties (Hidden, SetAccess = private)
    
    time_log            = []; % Log of associated property (accumulated when data is streaming)
    accel_raw_log       = []; % Log of associated property (accumulated when data is streaming)
    gyro_raw_log        = []; % Log of associated property (accumulated when data is streaming)
    motor_emf_raw_log   = []; % Log of associated property (accumulated when data is streaming)
    motor_pwm_raw_log   = []; % Log of associated property (accumulated when data is streaming)
    imu_rpy_filt_log    = []; % Log of associated property (accumulated when data is streaming)
    accel_filt_log      = []; % Log of associated property (accumulated when data is streaming)
    gyro_filt_log       = []; % Log of associated property (accumulated when data is streaming)
    motor_emf_filt_log  = []; % Log of associated property (accumulated when data is streaming)
    quat_log            = []; % Log of associated property (accumulated when data is streaming)
    odo_log             = []; % Log of associated property (accumulated when data is streaming)
    accel_one_log       = []; % Log of associated property (accumulated when data is streaming)
    vel_log             = []; % Log of associated property (accumulated when data is streaming)
    
    % time_init - Seconds since epoch (from built-in command 'now')
    time_init = [];
    
    % num_skip - Number of bytes to skip reading in BytesAvailableFcn
    num_skip = 0;
    
    % buffer - Buffer (local) for incoming serial data
    buffer = [];
    
    % seq - Current command sequence number
    seq = 1;
    
    % response_packet - Current command response packet
    response_packet = [];
    
    % machine_byte_order - Characteristic of computer architecture.
    machine_byte_order = [];
    
  end
  
  events (NotifyAccess = private)
    
    NewPowerNotification      % Triggered when async message is received
    NewLevel1Diagnostic       % Triggered when async message is received
    NewDataStreaming          % Triggered when async message is received
    NewConfigBlockContents    % Triggered when async message is received
    NewPreSleepWarning        % Triggered when async message is received
    NewMacroMarkers           % Triggered when async message is received
    NewCollisionDetected      % Triggered when async message is received
    NewOrbBasicMessage        % Triggered when async message is received
    NewSelfLevelResult        % Triggered when async message is received
    NewGyroAxisLimitExceeded  % Triggered when async message is received
    NewSpheroSoulData         % Triggered when async message is received
    NewLevelUp                % Triggered when async message is received
    NewShieldDamage           % Triggered when async message is received
    NewXpUpdate               % Triggered when async message is received
    NewBoostUpdate            % Triggered when async message is received
    
  end
  
  methods
    
    %% === Constructor and Overrides ======================================
    function s = SpheroCore()
      % SpheroCore  Constructs object.
      %   A bluetooth connection to Sphero must subsequently be established
      %   before interacting with the device.
      %
      %   See also:
      %     ConnectDevice
      
      % get architecture information and store endianness
      [~,~,endianness] = computer;
      if strcmp('L',endianness)
        s.machine_byte_order = 'little-endian';
      elseif strcmp('B',endianness)
        s.machine_byte_order = 'big-endian';
      end
      assert(~isempty(s.machine_byte_order),...
        'Failed to set machine byte order.');
      
      % attach listeners
      addlistener(s,'NewPowerNotification'    ,@s.OnNewPowerNotification);
      addlistener(s,'NewLevel1Diagnostic'     ,@s.OnNewLevel1Diagnostic);
      addlistener(s,'NewDataStreaming'        ,@s.OnNewDataStreaming);
      addlistener(s,'NewConfigBlockContents'  ,@s.OnNewConfigBlockContents);
      addlistener(s,'NewPreSleepWarning'      ,@s.OnNewPreSleepWarning);
      addlistener(s,'NewMacroMarkers'         ,@s.OnNewMacroMarkers);
      addlistener(s,'NewCollisionDetected'    ,@s.OnNewCollisionDetected);
      addlistener(s,'NewOrbBasicMessage'      ,@s.OnNewOrbBasicMessage);
      addlistener(s,'NewSelfLevelResult'      ,@s.OnNewSelfLevelResult);
      addlistener(s,'NewGyroAxisLimitExceeded',@s.OnNewGyroAxisLimitExceeded);
      addlistener(s,'NewSpheroSoulData'       ,@s.OnNewSpheroSoulData);
      addlistener(s,'NewLevelUp'              ,@s.OnNewLevelUp);
      addlistener(s,'NewShieldDamage'         ,@s.OnNewShieldDamage);
      addlistener(s,'NewXpUpdate'             ,@s.OnNewXpUpdate);
      addlistener(s,'NewBoostUpdate'          ,@s.OnNewBoostUpdate);
      
      s.time_init = now * s.SECONDS_PER_DAY;
      
    end
    
    function delete(s)
      % delete  Overloaded method cleans up after this object.
      %   Some properties must be cleaned up before they're orphaned by
      %   destroying this object's handle.
      %
      %   See also:
      %     bt
      % s.DEBUG_PRINT_FUNCTION_NAME(dbstack(1));
      
      if ~isempty(s.bt) % need to delete this object
        if strcmp('open',s.bt.Status) % need to close connection first
          fclose(s.bt);
        end
        delete(s.bt);
      end
      
    end
    
    %% === Getters ========================================================
    function val = get.time_since_init(s)
      val = now * s.SECONDS_PER_DAY - s.time_init;
    end
    
    %% === Setters ========================================================
    function set.time(s,val)
      s.time = val;
    end
    
    function set.accel_raw(s,val)
      s.accel_raw = val * s.ACCEL_RAW_UNITS_PER_LSB;
    end
    
    function set.gyro_raw(s,val)
      s.gyro_raw = val * s.GYRO_RAW_UNITS_PER_LSB;
    end
    
    function set.motor_emf_raw(s,val)
      s.motor_emf_raw = val * s.MOTOR_EMF_RAW_UNITS_PER_LSB;
    end
    
    function set.motor_pwm_raw(s,val)
      s.motor_pwm_raw = val * s.MOTOR_PWM_RAW_UNITS_PER_LSB;
    end
    
    function set.imu_rpy_filt(s,val)
      s.imu_rpy_filt = val * s.IMU_RPY_FILT_UNITS_PER_LSB;
    end
    
    function set.accel_filt(s,val)
      s.accel_filt = val * s.ACCEL_FILT_UNITS_PER_LSB;
    end
    
    function set.gyro_filt(s,val)
      s.gyro_filt = val * s.GYRO_FILT_UNITS_PER_LSB;
    end
    
    function set.motor_emf_filt(s,val)
      s.motor_emf_filt = val * s.MOTOR_EMF_FILT_UNITS_PER_LSB;
    end
    
    function set.quat(s,val)
      s.quat = val * s.QUAT_UNITS_PER_LSB;
      s.quat = s.quat./norm(s.quat); % renormalize quaternion
    end
    
    function set.odo(s,val)
      odo = val * s.ODO_UNITS_PER_LSB;
      s.odo = odo;
    end
    
    function set.accel_one(s,val)
      s.accel_one = val * s.ACCEL_ONE_UNITS_PER_LSB;
    end
    
    function set.vel(s,val)
      s.vel = val * s.VEL_UNITS_PER_LSB;
    end
    
    function set.sog(s,val)
      s.sog = val * s.SOG_UNITS_PER_LSB;
    end
    
    function set.NewPowerNotificationFcn(s,func)
      s.NewPowerNotificationFcn = s.AssertUserCallbackFcn(func,'NewPowerNotificationFcn');
    end
    
    function set.NewLevel1DiagnosticFcn(s,func)
      s.NewLevel1DiagnosticFcn = s.AssertUserCallbackFcn(func,'NewLevel1DiagnosticFcn');
    end
    
    function set.NewDataStreamingFcn(s,func)
      s.NewDataStreamingFcn = s.AssertUserCallbackFcn(func,'NewDataStreamingFcn');
    end
    
    function set.NewConfigBlockContentsFcn(s,func)
      s.NewConfigBlockContentsFcn = s.AssertUserCallbackFcn(func,'NewConfigBlockContentsFcn');
    end
    
    function set.NewPreSleepWarningFcn(s,func)
      s.NewPreSleepWarningFcn = s.AssertUserCallbackFcn(func,'NewPreSleepWarningFcn');
    end
    
    function set.NewMacroMarkersFcn(s,func)
      s.NewMacroMarkersFcn = s.AssertUserCallbackFcn(func,'NewMacroMarkersFcn');
    end
    
    function set.NewCollisionDetectedFcn(s,func)
      s.NewCollisionDetectedFcn = s.AssertUserCallbackFcn(func,'NewCollisionDetectedFcn');
    end
    
    function set.NewOrbBasicMessageFcn(s,func)
      s.NewOrbBasicMessageFcn = s.AssertUserCallbackFcn(func,'NewOrbBasicMessageFcn');
    end
    
    function set.NewSelfLevelResultFcn(s,func)
      s.NewSelfLevelResultFcn = s.AssertUserCallbackFcn(func,'NewSelfLevelResultFcn');
    end
    
    function set.NewGyroAxisLimitExceededFcn(s,func)
      s.NewGyroAxisLimitExceededFcn = s.AssertUserCallbackFcn(func,'NewGyroAxisLimitExceededFcn');
    end
    
    function set.NewSpheroSoulDataFcn(s,func)
      s.NewSpheroSoulDataFcn = s.AssertUserCallbackFcn(func,'NewSpheroSoulDataFcn');
    end
    
    function set.NewLevelUpFcn(s,func)
      s.NewLevelUpFcn = s.AssertUserCallbackFcn(func,'NewLevelUpFcn');
    end
    
    function set.NewShieldDamageFcn(s,func)
      s.NewShieldDamageFcn = s.AssertUserCallbackFcn(func,'NewShieldDamageFcn');
    end
    
    function set.NewXpUpdateFcn(s,func)
      s.NewXpUpdateFcn = s.AssertUserCallbackFcn(func,'NewXpUpdateFcn');
    end
    
    function set.NewBoostUpdateFcn(s,func)
      s.NewBoostUpdateFcn = s.AssertUserCallbackFcn(func,'NewBoostUpdateFcn');
    end
    
    %% === Utility ========================================================
    function ClearLogs(s)
      % ClearLogs  Initializes the data logs to empty - discards data.
      
      s.time_log            = [];
      s.accel_raw_log       = [];
      s.gyro_raw_log        = [];
      s.motor_emf_raw_log   = [];
      s.motor_pwm_raw_log   = [];
      s.imu_rpy_filt_log    = [];
      s.accel_filt_log      = [];
      s.gyro_filt_log       = [];
      s.motor_emf_filt_log  = [];
      s.quat_log            = [];
      s.odo_log             = [];
      s.accel_one_log       = [];
      s.vel_log             = [];
      
    end
    
    % === Device Control ==================================================
    function fail = ConnectDevice(s,remote_name)
      % Connect Device
      %   Connects to Sphero using Matlab Bluetooth object (bt property).
      %   Optional parameter |remote_name| specifies a partial string
      %   occuring in the remote name of the desired bluetooth device.
      fail = true;
      % set user-supplied remote_name empty so it isn't used later
      if nargin < 2
        remote_name = [];
      else
        if ischar(remote_name)
          remote_name = {remote_name};
        end
      end
      
      if ~isempty(s.bt) % bluetooth has already been initialized
        % do some magic to get bt into a state where it can be fopen()'d
        % TODO implement management of connection/reconnection automatically.
        s.DEBUG_PRINT('Closing bluetooth port');
        if strcmp('open',s.bt.Status)
          fclose(s.bt);
        end
      else
        % instantiate bt property
        
        % returns a hardware info struct for bluetooth devices with
        % RemoteName containing a partial match of remote_name and fields:
        % .RemoteNames .RemoteIds .NumDevices
        
        if isempty(remote_name)
          hw = s.FindSpheroDevice(remote_name);
          
          if hw.NumDevices < 1
            s.DEBUG_PRINT('Failed to find devices for connection.');
            return;
          end
          remote_name = hw.RemoteNames;
        end
        
        % instantiate bluetooth object
        for ii = 1:length(remote_name)
          if ~isempty(s.bt), break; end
          full_remote_name = remote_name{ii};
          s.DEBUG_PRINT('Attempting to connect to remote name %s ...',...
            full_remote_name);
          for nn = 1:s.BT_NUM_CONNECTION_ATTEMPTS
            s.DEBUG_PRINT('Attempt number %d of %d',...
              nn,s.BT_NUM_CONNECTION_ATTEMPTS);
            try
              s.bt = Bluetooth(...
                full_remote_name,s.BT_CHANNEL,...
                'BytesAvailableFcnMode','byte',...
                'BytesAvailableFcnCount',1,...
                'BytesAvailableFcn',@s.BytesAvailableFcn,...
                'InputBufferSize',8192);
            catch e
              
              s.bt
              continue;
            end
            % stop trying if bt is initialized
            if ~isempty(s.bt), break; end
          end
        end
        
        if isempty(s.bt) % connection failed, bail out
          s.DEBUG_PRINT('Failed to connect to all devices');
          return;
        end
        
        s.DEBUG_PRINT('Connected to device with remote name %s',...
          full_remote_name);
      end
      
      s.DEBUG_PRINT('Opening port for communication');
      pause(1);
      
      for ii = 1:3
        try
          fopen(s.bt);
        catch e
        end
        if strcmp(s.bt.Status,'open'), break; end
      end
      
      pause(1)
      
      % verify connection
      if strcmp('open',s.bt.Status) && ~s.Ping()
        fail = false;
        % get versioning info
        s.GetVersioning();
        % make it green!
        s.SetRGBLEDOutput([0,1,0],0);
      end
      
    end
    
    function hw = FindSpheroDevice(s,remote_name)
      % FindSpheroDevice  Returns a struct of Bluetooth device info
      %   Optional input parameter remote_name specifies a partial match to
      %   the name of the desired device. Remote name defaults to 'Sphero'
      %   when empty or omitted. The output hw is a struct that is similar
      %   to the ouput of instrhwinfo, but only includes devices with
      %   partial match to remote_name.
      
      if nargin < 2 || isempty(remote_name)
        remote_name = 'Sphero';
      end
      
      % get info about available bluetooth devices
      hwinfo = instrhwinfo('Bluetooth');
      
      % find devices indices containing user-supplied remote name
      if ~isempty(remote_name)
        ids = find(~cellfun('isempty',strfind(hwinfo.RemoteNames,remote_name)));
      else
        ids = [];
      end
      
      num = length(ids);
      
      if num == 0
        % no devices found
        s.DEBUG_PRINT('No devices found containing remote_name %s.',...
          remote_name);
      elseif num == 1
        s.DEBUG_PRINT('One device found containing remote name %s.',...
          hwinfo.RemoteNames{ids});
      elseif num > 1
        % multiple devices found
        s.DEBUG_PRINT('Multiple (%d) devices found containing remote name %s.',...
          length(ids),remote_name);
        % generate list of device names
        tmp = '';
        for ii = 1:length(ids)
          tmp = [tmp,' "',hwinfo.RemoteNames{ids(ii)},'"'];
        end
        s.DEBUG_PRINT('Queueing devices these devices for connection:%s.',...
          tmp);
      else
        % something went very wrong
        return;
      end
      
      % return a struct similar to hwinfo that only contains
      % .RemoteNames .RemoteIds .NumDevices
      hw.RemoteNames = hwinfo.RemoteNames(ids);
      hw.RemoteIDs = hwinfo.RemoteIDs(ids);
      hw.NumDevices = num;
      
    end
    
  end
  
  methods (Access = protected)
    
    %% === Utility ========================================================
    function WARN_PRINT(s,varargin)
      if s.WARN_PRINT_FLAG
        fprintf('%s WARN  >> %s\n',mfilename,sprintf(varargin{:}));
      end
    end
    
    function DEBUG_PRINT(s,varargin)
      if s.DEBUG_PRINT_FLAG
        fprintf('%s DEBUG >> %s\n',mfilename,sprintf(varargin{:}));
      end
    end
    
    function DEBUG_PRINT_FUNCTION_NAME(s,stack)
      if s.DEBUG_PRINT_FUNCTION_NAME_FLAG
        if ~isempty(stack)
          s.DEBUG_PRINT('%s()',stack(1).name);
        end
      end
    end
    
    function INFO_PRINT(s,varargin)
      if s.INFO_PRINT_FLAG
        fprintf('%s INFO  >> %s\n',mfilename,sprintf(varargin{:}));
      end
    end
    
    function integer = IntegerFromByteArray(s,byteArray,precision)
      byteArray = uint8(byteArray);
      integer = typecast(byteArray,precision);
      if strcmp('little-endian',s.machine_byte_order)
        integer = swapbytes(integer);
      end
    end
    
    function byteArray = ByteArrayFromInteger(s,integer,precision)
      integer = cast(integer,precision);
      if strcmp('little-endian',s.machine_byte_order)
        integer = swapbytes(integer);
      end
      byteArray = typecast(integer,'uint8');
    end
    
    function [value,array] = ShiftOutInt16FromByteArray(s,byteArray,num)
      if nargin < 3
        num = 1;
      end
      if num < 1
        return;
      elseif length(byteArray) < (2*num)
        return;
      end
      
      value = zeros(num,1);
      array = byteArray;
      for ii = 1:num
        value(ii) = s.IntegerFromByteArray(array(1:2),'int16');
        array = array(3:end); % should return empty if length(byteArray)<3
      end
    end
    
    function InitNewDataLogs(s)
      s.time_log            = [s.time_log           ,nan];
      s.accel_raw_log       = [s.accel_raw_log      ,nan(3,1)];
      s.gyro_raw_log        = [s.gyro_raw_log       ,nan(3,1)];
      s.motor_emf_raw_log   = [s.motor_emf_raw_log  ,nan(2,1)];
      s.motor_pwm_raw_log   = [s.motor_pwm_raw_log  ,nan(2,1)];
      s.imu_rpy_filt_log    = [s.imu_rpy_filt_log   ,nan(3,1)];
      s.accel_filt_log      = [s.accel_filt_log     ,nan(3,1)];
      s.gyro_filt_log       = [s.gyro_filt_log      ,nan(3,1)];
      s.motor_emf_filt_log  = [s.motor_emf_filt_log ,nan(2,1)];
      s.quat_log            = [s.quat_log           ,nan(4,1)];
      s.odo_log             = [s.odo_log            ,nan(2,1)];
      s.accel_one_log       = [s.accel_one_log      ,nan];
      s.vel_log             = [s.vel_log            ,nan(2,1)];
    end
    
    
    %% === Protocol =======================================================
    function [fail,resp] = WriteClientCommandPacket(s,did,cid,data,...
        reset_timeout_flag,answer_flag)
      % SendCommand  Writes commands to the device.
      %   Constructs and writes the client command packets defined in
      %   Sphero API.
      %   All input parameters are required except for |data|. When |data|
      %   is not passed, this method assumes that there is no data for the
      %   specified command. This behavior is the same as explicitly
      %   passing |data = []|.
      %   reset_timeout_flag and answer_flag are optional parameters.
      % s.DEBUG_PRINT_FUNCTION_NAME(dbstack(1));
      
      fail = true;
      resp = [];
      
      if nargin < 3
        % too short to be a valid command
        return;
      elseif nargin < 4
        % assume this command has no data
        data = [];
      elseif isempty(s.bt) || strcmp('closed',s.bt.Status)
        %
        return;
      end
      
      if isempty(reset_timeout_flag) || nargin < 5
        reset_timeout_flag = s.reset_timeout_flag;
      end
      if isempty(answer_flag) || nargin < 6
        answer_flag = s.answer_flag;
      end
      
      % packet format is:
      % [ sop1 | sop2 | did | cid | seq | dlen | <data> | chk ]
      
      % start of packet 1 is constant
      sop1 = s.SOP1;
      
      % start of packet 2 is described by constant top nibble with the
      % bottom nibble (bits 0-3) a four-bit field. Only bits 0 and 1 have
      % documented use. So I call bits 2 and 3 "RESERVED" by assumption.
      % init
      sop2 = s.SOP2_MASK_BASE;
      sop2 = bitor(sop2,s.SOP2_MASK_RESERVED,'uint8');
      if reset_timeout_flag
        sop2 = bitor(sop2,s.SOP2_MASK_RESET_TIMEOUT,'uint8');
      end
      
      if answer_flag
        sop2 = bitor(sop2,s.SOP2_MASK_ANSWER,'uint8');
        seq = s.GetNewCmdSeq();
      else
        seq = 0;
      end
      
      % assume did, cid, seq are all okay ...
      
      % figure out dlen from data
      if isempty(data)
        dlen = 1;
      else
        dlen = length(data)+1;
      end
      
      % assume data is okay ...
      
      % compute checksum beginning with did
      chk = bitcmp(mod(sum(uint8([did,cid,seq,dlen,data])),256),'uint8');
      
      % make packet
      packet = uint8([sop1,sop2,did,cid,seq,dlen,data,chk]);
      
      s.DEBUG_PRINT(' sending packet: %s',sprintf('%0.2X ',packet));
      
      % write packet
      fwrite(s.bt,packet,'uint8');
      
      % TODO something about waiting for the command to respond if
      % answer_flag is set
      if answer_flag
        [fail,resp] = s.WaitForCommandResponse();
      else
        fail = [];
      end
      
    end
    
    function BytesAvailableFcn(s,src,evt)
      % BytesAvailableFcn  Reads incoming data into local buffer.
      %   This function is a callback triggered by the |Bluetooth| object
      %   |bt| when one byte arrives in its incomding data buffer. All it
      %   does is forward incoming bytes from the incoming buffer of |bt|
      %   to a property of this class named |buffer| before calling the
      %   |SpinProtocol| method take action on the incoming data.
      
      % push one byte onto local buffer
      if s.num_skip > 0
        s.num_skip = s.num_skip - 1;
      else
        s.buffer = [ s.buffer , fread(s.bt,1,'uint8') ];
        s.SpinProtocol();
      end
    end
    
    function SpinProtocol(s)
      % SpinProtocol  Reads local input buffer to parse RSP and MSG
      %  Invoked by the Bluetooth callback BytesAvailableFcn
      
      if length(s.buffer) < 6, return; end % bail if not enough data for a packet
      
      % grab first two bytes and bail on protocol fault
      sop1 = s.buffer(1);
      sop2 = s.buffer(2);
      if sop1 ~= s.SOP1
        s.DEBUG_PRINT('Missed SOP1 byte');
        s.buffer = s.buffer(2:end);
        return;
      elseif ~any( sop2 == [s.SOP2_RSP,s.SOP2_ASYNC] )
        s.DEBUG_PRINT('Missed SOP2 byte');
        s.buffer = s.buffer(3:end);
        return;
      end
      % sop1 and sop2 are both valid now
      
      % proceed to read in
      if sop2 == s.SOP2_RSP
        % response format
        % [ sop1 | sop2 | mrsp | seq | dlen | <data> | chk ]
        
        mrsp = s.buffer(3);
        seq = s.buffer(4);
        dlen = s.buffer(5);
        
        % read data into buffer
        % if the whole packet isn't in the buffer yet, this part will
        % attempt a blocking read on the assumed missing bytes.
        num_bytes = 5+dlen - length(s.buffer);
        new_bytes = [];
        if num_bytes > 0
          new_bytes = fread(s.bt,num_bytes,'uint8')';
        end
        s.buffer = [s.buffer,new_bytes];
        s.num_skip = s.num_skip + num_bytes; % adjustment for BytesAvailableFcn to ignore the triggers for bytes read manually
        
        % move packet out of buffer
        packet = s.buffer(1:5+dlen);
        s.buffer = s.buffer(5+dlen+1:end);
        
        % grab data, chk, validate chk
        data = packet(6:end-1);
        chk = packet(end);
        chk_cmp = bitcmp(mod(sum(uint8(packet(3:end-1))),256),'uint8');
        if chk ~= chk_cmp, return; end
        
        s.response_packet.sop1 = sop1;
        s.response_packet.sop2 = sop2;
        s.response_packet.mrsp = mrsp;
        s.response_packet.seq  = seq;
        s.response_packet.dlen = dlen;
        s.response_packet.data = data;
        s.response_packet.chk  = chk;
        
      elseif sop2 == s.SOP2_ASYNC
        % async message format
        % [ sop1 | sop2 | id_code | dlen_msb | dlen_lsb | <data> | chk ]
        
        id_code = s.buffer(3);
        dlen_msb = s.buffer(4);
        dlen_lsb = s.buffer(5);
        dlen = s.IntegerFromByteArray([dlen_msb,dlen_lsb],'uint16');
        
        % read data into buffer
        % if the whole packet isn't in the buffer yet, this part will
        % attempt a blocking read on the assumed missing bytes.
        num_bytes = double(5+dlen - length(s.buffer));
        new_bytes = [];
        if num_bytes > 0
          new_bytes = fread(s.bt,num_bytes,'uint8')';
        end
        s.buffer = [s.buffer,new_bytes];
        s.num_skip = s.num_skip + num_bytes; % adjustment for BytesAvailableFcn to ignore the triggers for bytes read manually
        
        % move packet out of buffer
        packet = s.buffer(1:5+dlen);
        s.buffer = s.buffer(5+dlen+1:end);
        
        % grab data, chk, validate chk
        data = packet(6:end-1);
        chk = packet(end);
        chk_cmp = bitcmp(mod(sum(uint8(packet(3:end-1))),256),'uint8');
        if chk ~= chk_cmp, return; end
        
        s.DEBUG_PRINT('received packet: %s',sprintf('%0.2X ',packet));
        
        % handle the message
        switch id_code
          case s.ID_CODE_POWER_NOTIFICATIONS
            s.HandlePowerNotification(data);
          case s.ID_CODE_LEVEL_1_DIAGNOSTIC_RESPONSE
            s.HandleLevel1Diagnostic(data);
          case s.ID_CODE_SENSOR_DATA_STREAMING
            s.HandleDataStreaming(data);
          case s.ID_CODE_CONFIG_BLOCK_CONTENTS
            s.HandleConfigBlockContents(data);
          case s.ID_CODE_PRE_SLEEP_WARNING
            s.HandlePreSleepWarning(data);
          case s.ID_CODE_MACRO_MARKERS
            s.HandleMacroMarkers(data);
          case s.ID_CODE_COLLISION_DETECTED
            s.HandleCollisionDetected(data);
          case s.ID_CODE_ORB_BASIC_PRINT_MESSAGE
            s.HandleOrbBasic(data,'print');
          case s.ID_CODE_ORB_BASIC_ERROR_MESSAGE_ASCII
            s.HandleOrbBasic(data,'error-ascii');
          case s.ID_CODE_ORB_BASIC_ERROR_MESSAGE_BINARY
            s.HandleOrbBasic(data,'error-binary');
          case s.ID_CODE_SELF_LEVEL_RESULT
            s.HandleSelfLevelResult(data);
          case s.ID_CODE_GYRO_AXIS_LIMIT_EXCEEDED
            s.HandleGyroAxisLimitExceeded(data);
          case s.ID_CODE_SPHEROS_SOUL_DATA
            s.HandleSpheroSoulData(data);
          case s.ID_CODE_LEVEL_UP_NOTIFICATION
            s.HandleLevelUpNotification(data);
          case s.ID_CODE_SHIELD_DAMAGE_NOTIFICATION
            s.HandleShieldDamageNotification(data);
          case s.ID_CODE_XP_UPDATE_NOTIFICATION
            s.HandleXpUpdateNotification(data);
          case s.ID_CODE_BOOST_UPDATE_NOTIFICATION
            s.HandleBoostUpdateNotification(data);
          otherwise
            s.DEBUG_PRINT('Unsupported asyncronous message!');
        end
      end
    end
    
    function [fail,resp] = WaitForCommandResponse(s)
      % WaitForCommandResponse  Wait for response to syncronous commands
      %   This method is called after writing a command in
      %   WriteClientCommandPacket if answer_flag is set. It polls response_packet
      %   until SpinProtocol has set it with a packet comes in with seq ==
      %   seq.
      
      % response format
      % [ sop1 | sop2 | mrsp | seq | dlen | <data> | chk ]
      fail = true;
      resp = [];
      
      tic; t = 0;
      while fail && toc < s.WAIT_FOR_CMD_RSP_TIMEOUT
        
        if ~isempty(s.response_packet) && (s.response_packet.seq == s.seq)
          
          % check for successful response
          fail = s.CheckResponseFailure();
          dlen = s.response_packet.dlen;
          if  ~fail && (dlen > 0)
            resp = s.response_packet.data;
          end
          s.response_packet = [];
        else
          pause(s.WAIT_FOR_CMD_RSP_DELAY);
        end
        t = toc;
      end
      
    end
    
    function new_seq = GetNewCmdSeq(s)
      % s.DEBUG_PRINT_FUNCTION_NAME(dbstack(1));
      
      if s.seq ~= 255
        new_seq = s.seq + 1;
      else
        new_seq = 1;
      end
      s.seq = new_seq;
    end
    
    function  fail = CheckResponseFailure(s)
      fail = true;
      switch s.response_packet.mrsp
        case 0
          fail = false;
          return;
        case s.ORBOTIX_RSP_CODE_EGEN
          msg = s.ORBOTIX_RSP_CODE_EGEN;
        case s.ORBOTIX_RSP_CODE_ECHKSUM
          msg = s.ORBOTIX_RSP_CODE_ECHKSUM;
        case s.ORBOTIX_RSP_CODE_EFRAG
          msg = s.ORBOTIX_RSP_CODE_EFRAG;
        case s.ORBOTIX_RSP_CODE_EBAD_CMD
          msg = s.ORBOTIX_RSP_CODE_EBAD_CMD;
        case s.ORBOTIX_RSP_CODE_EUNSUPP
          msg = s.ORBOTIX_RSP_CODE_EUNSUPP;
        case s.ORBOTIX_RSP_CODE_EBAD_MSG
          msg = s.ORBOTIX_RSP_CODE_EBAD_MSG;
        case s.ORBOTIX_RSP_CODE_EPARAM
          msg = s.ORBOTIX_RSP_CODE_EPARAM;
        case s.ORBOTIX_RSP_CODE_EEXEC
          msg = s.ORBOTIX_RSP_CODE_EEXEC;
        case s.ORBOTIX_RSP_CODE_EBAD_DID
          msg = s.ORBOTIX_RSP_CODE_EBAD_DID;
        case s.ORBOTIX_RSP_CODE_MEM_BUSY
          msg = s.ORBOTIX_RSP_CODE_MEM_BUSY;
        case s.ORBOTIX_RSP_CODE_BAD_PASSWORD
          msg = s.ORBOTIX_RSP_CODE_BAD_PASSWORD;
        case s.ORBOTIX_RSP_CODE_POWER_NOGOOD
          msg = s.ORBOTIX_RSP_CODE_POWER_NOGOOD;
        case s.ORBOTIX_RSP_CODE_PAGE_ILLEGAL
          msg = s.ORBOTIX_RSP_CODE_PAGE_ILLEGAL;
        case s.ORBOTIX_RSP_CODE_FLASH_FAIL
          msg = s.ORBOTIX_RSP_CODE_FLASH_FAIL;
        case s.ORBOTIX_RSP_CODE_MA_CORRUPT
          msg = s.ORBOTIX_RSP_CODE_MA_CORRUPT;
        case s.ORBOTIX_RSP_CODE_MSG_TIMEOUT
          msg = s.ORBOTIX_RSP_CODE_MSG_TIMEOUT;
        otherwise
          msg = 'Unknown failure.';
      end
      s.WARN_PRINT('Command failed: %s',msg);
    end
    
    
    function SetDataStreamingSensors(s,sensors_spec)
      % DataStreamingMasksFromSensorsCellStr  Create sensors masks
      %   Creates sensor masks mask and mask2 from a cell array of strings
      %   sensors. These masks are used in the SetDataStreaming to select
      %   streaming data elements.
      %
      %   See also:
      %     SetDataStreaming
      
      mask = 0;
      mask2 = 0;
      
      % create a properly ordered list of enabled sensor groups and the
      % number of bytes per data frame
      sensors_spec = unique(sensors_spec); % throw out duplicates
      
      sensors = cell(s.NUM_STREAMING_SENSOR_GROUPS,1);
      num_bytes = 0;
      
      for ii = 1:length(sensors_spec)
        sensor = sensors_spec{ii};
        mask_bits = 0;
        mask2_bits = 0;
        switch sensor
          case 'accel_raw'
            sensors{1} = sensor;
            mask_bits = bitor(mask_bits,s.MASK_ACCEL_X_RAW,'uint32');
            mask_bits = bitor(mask_bits,s.MASK_ACCEL_Y_RAW,'uint32');
            mask_bits = bitor(mask_bits,s.MASK_ACCEL_Z_RAW,'uint32');
            num_bytes = num_bytes + 6;
          case 'gyro_raw'
            sensors{2} = sensor;
            mask_bits = bitor(mask_bits,s.MASK_GYRO_X_RAW,'uint32');
            mask_bits = bitor(mask_bits,s.MASK_GYRO_Y_RAW,'uint32');
            mask_bits = bitor(mask_bits,s.MASK_GYRO_Z_RAW,'uint32');
            num_bytes = num_bytes + 6;
          case 'motor_emf_raw'
            sensors{3} = sensor;
            mask_bits = bitor(mask_bits,s.MASK_MOTOR_RT_EMF_RAW,'uint32');
            mask_bits = bitor(mask_bits,s.MASK_MOTOR_LT_EMF_RAW,'uint32');
            num_bytes = num_bytes + 4;
          case 'motor_pwm_raw'
            sensors{4} = sensor;
            mask_bits = bitor(mask_bits,s.MASK_MOTOR_LT_PWM_RAW,'uint32');
            mask_bits = bitor(mask_bits,s.MASK_MOTOR_RT_PWM_RAW,'uint32');
            num_bytes = num_bytes + 4;
          case 'imu_filt'
            sensors{5} = sensor;
            mask_bits = bitor(mask_bits,s.MASK_IMU_PITCH_FILT,'uint32');
            mask_bits = bitor(mask_bits,s.MASK_IMU_ROLL_FILT,'uint32');
            mask_bits = bitor(mask_bits,s.MASK_IMU_YAW_FILT,'uint32');
            num_bytes = num_bytes + 6;
          case 'accel_filt'
            sensors{6} = sensor;
            mask_bits = bitor(mask_bits,s.MASK_ACCEL_X_FILT,'uint32');
            mask_bits = bitor(mask_bits,s.MASK_ACCEL_Y_FILT,'uint32');
            mask_bits = bitor(mask_bits,s.MASK_ACCEL_Z_FILT,'uint32');
            num_bytes = num_bytes + 6;
          case 'gyro_filt'
            sensors{7} = sensor;
            mask_bits = bitor(mask_bits,s.MASK_GYRO_X_FILT,'uint32');
            mask_bits = bitor(mask_bits,s.MASK_GYRO_Y_FILT,'uint32');
            mask_bits = bitor(mask_bits,s.MASK_GYRO_Z_FILT,'uint32');
            num_bytes = num_bytes + 6;
          case 'motor_emf_filt'
            sensors{8} = sensor;
            mask_bits = bitor(mask_bits,s.MASK_MOTOR_RT_EMF_FILT,'uint32');
            mask_bits = bitor(mask_bits,s.MASK_MOTOR_LT_EMF_FILT,'uint32');
            num_bytes = num_bytes + 4;
          case 'quat'
            sensors{9} = sensor;
            mask2_bits = bitor(mask2_bits,s.MASK2_QUAT_Q0,'uint32');
            mask2_bits = bitor(mask2_bits,s.MASK2_QUAT_Q1,'uint32');
            mask2_bits = bitor(mask2_bits,s.MASK2_QUAT_Q2,'uint32');
            mask2_bits = bitor(mask2_bits,s.MASK2_QUAT_Q3,'uint32');
            num_bytes = num_bytes + 8;
          case 'odo'
            sensors{10} = sensor;
            mask2_bits = bitor(mask2_bits,s.MASK2_ODO_X,'uint32');
            mask2_bits = bitor(mask2_bits,s.MASK2_ODO_Y,'uint32');
            num_bytes = num_bytes + 4;
          case 'accel_one'
            sensors{11} = sensor;
            mask2_bits = bitor(mask2_bits,s.MASK2_ACCEL_ONE,'uint32');
            num_bytes = num_bytes + 2;
          case 'vel'
            sensors{12} = sensor;
            mask2_bits = bitor(mask2_bits,s.MASK2_VEL_X,'uint32');
            mask2_bits = bitor(mask2_bits,s.MASK2_VEL_Y,'uint32');
            num_bytes = num_bytes + 4;
          otherwise
            % bad sensor given
            s.INFO_PRINT('Sensor %s not supported!',sensor);
        end
        
        mask = bitor(mask,mask_bits,'uint32');
        mask2 = bitor(mask2,mask2_bits,'uint32');
        
      end
      
      s.data_streaming_info.sensors = sensors(~cellfun('isempty',sensors));
      s.data_streaming_info.mask = mask;
      s.data_streaming_info.mask2 = mask2;
      s.data_streaming_info.num_bytes_per_frame = num_bytes;
    end
    
    %% === Async Message Handlers =========================================
    % These functions are called by SpinProtocol when an async MSG is
    % parsed in from the bluetooth input buffer. Each handler performs
    % necessary processing on its message data before triggering its
    % corresponding event with notify(s,NewMSG). Then the NewMSG events
    % trigger the OnNewMSG listeners wherein user-specified callbacks
    % stored in the NewMSGFcn properties are called is they have been set.
    function HandlePowerNotification(s,data)
      
      notify(s,'NewPowerNotification');
    end
    
    function HandleLevel1Diagnostic(s,data)
      header = 'Sphero Level 1 Diagnostics';
      date_string = datestr(now,'yyyy-mm-dd_HH-MM-SS-FFF');
      % check for existing file (unlikely to happen)
      fname = sprintf('Sphero-Level-1-Diagnostics_%s.txt',...
        date_string);
      if exist(fname,'file')
        warning('Failed to create log file:\n\t%s\n',fname);
        return;
      end
      % open file
      fid = fopen(fname,'w');
      if fid < 0
        warning('Failed to create log file:\n\t%s\n',fname);
        return;
      end
      % write to file
      fprintf(fid,'%s\n\t%s\n\n%s\n',header,date_string,data);
      fclose(fid);
      notify(s,'NewLevel1Diagnostic');
    end
    
    function HandleDataStreaming(s,data)
      if ~s.data_streaming_info.is_enabled
        return;
      elseif length(data) ~= s.data_streaming_info.num_bytes_per_frame * s.data_streaming_info.frame_count
        return;
      end
      sensors = s.data_streaming_info.sensors;
      BYTES_PER_VALUE = 2;
      s.DEBUG_PRINT('streaming data length: %d',length(data));
      if isempty(sensors)
        % no sensors... wtf?
        return;
      elseif length(sensors) ~= length(data)/BYTES_PER_VALUE
        % either data array or sensor state is wrong
        % TODO implement this sanity check
      end
      
      if s.data_streaming_info.num_samples == 0
        % initialize time start
        s.data_streaming_info.time_start = s.time_since_init;
      end
      
      byteArray = data;
      
      % read all data frames from this packet
      while ~isempty(byteArray)
        s.InitNewDataLogs();
        
        s.time = s.data_streaming_info.time_start + s.data_streaming_info.num_samples * s.data_streaming_info.sample_time;
        s.time_log(:,end) = s.time;
        
        for ii = 1:length(sensors)
          % process value based on sensors (in order)
          sensor = sensors{ii};
          switch sensor
            case 'accel_raw'
              [value,byteArray] = ShiftOutInt16FromByteArray(s,byteArray,3);
              s.accel_raw = value;
              s.accel_raw_log(:,end) = s.accel_raw;
            case 'gyro_raw'
              [value,byteArray] = ShiftOutInt16FromByteArray(s,byteArray,3);
              s.gyro_raw = value;
              s.gyro_raw_log(:,end) = s.gyro_raw;
            case 'motor_emf_raw'
              [value,byteArray] = ShiftOutInt16FromByteArray(s,byteArray,2);
              s.motor_emf_raw = value;
              s.motor_emf_raw_log(:,end) = s.motor_emf_raw;
            case 'motor_pwm_raw'
              [value,byteArray] = ShiftOutInt16FromByteArray(s,byteArray,2);
              s.motor_pwm_raw = value;
              s.motor_pwm_raw_log(:,end) = s.motor_pwm_raw;
            case 'imu_rpy_filt'
              [value,byteArray] = ShiftOutInt16FromByteArray(s,byteArray,3);
              s.imu_rpy_filt = value;
              s.imu_rpy_filt_log(:,end) = s.imu_rpy_filt;
            case 'accel_filt'
              [value,byteArray] = ShiftOutInt16FromByteArray(s,byteArray,3);
              s.accel_filt = value;
              s.accel_filt_log(:,end) = s.accel_filt;
            case 'gyro_filt'
              [value,byteArray] = ShiftOutInt16FromByteArray(s,byteArray,3);
              s.gyro_filt = value;
              s.gyro_filt_log(:,end) = s.gyro_filt;
            case 'motor_emf_filt'
              [value,byteArray] = ShiftOutInt16FromByteArray(s,byteArray,2);
              s.motor_emf_filt = value;
              s.motor_emf_filt_log(:,end) = s.motor_emf_filt;
            case 'quat'
              [value,byteArray] = ShiftOutInt16FromByteArray(s,byteArray,4);
              s.quat = value;
              s.quat_log(:,end) = s.quat;
            case 'odo'
              [value,byteArray] = ShiftOutInt16FromByteArray(s,byteArray,2);
              s.odo = value;
              s.odo_log(:,end) = s.odo;
            case 'accel_one'
              [value,byteArray] = ShiftOutInt16FromByteArray(s,byteArray,1);
              s.accel_one = value;
              s.accel_one_log(:,end) = s.accel_one;
            case 'vel'
              [value,byteArray] = ShiftOutInt16FromByteArray(s,byteArray,2);
              s.vel = value;
              s.vel_log(:,end) = s.vel;
            otherwise
              % bad sensor given
              s.INFO_PRINT('Sensor %s not supported!',sensor);
          end
        end
        s.data_streaming_info.num_samples = s.data_streaming_info.num_samples + 1;
      end
      % turn data streaming off
      if s.data_streaming_info.num_samples == s.data_streaming_info.frame_count*s.data_streaming_info.packet_count
        s.data_streaming_info.is_enabled = false;
      end
      notify(s,'NewDataStreaming');
    end
    
    function HandleConfigBlockContents(s,data)
      notify(s,'NewConfigBlockContents');
    end
    
    function HandlePreSleepWarning(s,data)
      notify(s,'NewPreSleepWarning');
    end
    
    function HandleMacroMarkers(s,data)
      notify(s,'NewMacroMarkers');
    end
    
    function HandleCollisionDetected(s,data)
      if ~s.collision_info.is_enabled
        return;
      elseif length(data) ~= s.COL_DET_NUM_BYTES
        return;
      end
      %
      x = s.IntegerFromByteArray(data(1:2),'int16');
      y = s.IntegerFromByteArray(data(3:4),'int16');
      z = s.IntegerFromByteArray(data(5:6),'int16');
      direction = double([x;y;z]);
      ax = s.IntegerFromByteArray(data(7),'uint8');
      xmag = s.IntegerFromByteArray(data(8:9),'uint16');
      ymag = s.IntegerFromByteArray(data(10:11),'uint16');
      speed = s.IntegerFromByteArray(data(12),'uint8');
      timestamp = s.IntegerFromByteArray(data(13:16),'uint32');
      % assign to info property struct
      s.collision_info.direction = direction/norm(direction,2);
      s.collision_info.axis = ax;
      s.collision_info.planar_mag = [xmag;ymag];
      s.collision_info.speed = speed;
      s.collision_info.timestamp = timestamp;
      
      notify(s,'NewCollisionDetected');
    end
    
    function HandleOrbBasicMessage(s,data,spec)
      % spec is in {'print', 'error-ascii', 'error-binary'}
      notify(s,'NewOrbBasicMessage');
    end
    
    function HandleSelfLevelResult(s,data)
      notify(s,'NewSelfLevelResult');
    end
    
    function HandleGyroAxisLimitExceeded(s,data)
      notify(s,'NewGyroAxisLimitExceeded');
    end
    
    function HandleSpheroSoulData(s,data)
      notify(s,'NewSpheroSoulData');
    end
    
    function HandleLevelUp(s,data)
      notify(s,'NewLevelUp');
    end
    
    function HandleShieldDamage(s,data)
      notify(s,'NewShieldDamage');
    end
    
    function HandleXpUpdate(s,data)
      notify(s,'NewXpUpdate');
    end
    function HandleBoostUpdate(s,data)
      notify(s,'NewBoostUpdate');
    end
    
    %% === Event Callback Dispatchers =====================================
    function OnNewPowerNotification(s,src,evt)
      s.InvokeUserCallbackFcn(s.NewPowerNotificationFcn,s,[],'NewPowerNotificationFcn');
    end
    function OnNewLevel1Diagnostic(s,src,evt)
      s.InvokeUserCallbackFcn(s.NewLevel1DiagnosticFcn,s,[],'NewLevel1DiagnosticFcn');
    end
    function OnNewDataStreaming(s,src,evt)
      s.InvokeUserCallbackFcn(s.NewDataStreamingFcn,s,[],'NewDataStreamingFcn');
    end
    function OnNewConfigBlockContents(s,src,evt)
      s.InvokeUserCallbackFcn(s.NewConfigBlockContentsFcn,s,[],'NewConfigBlockContentsFcn');
    end
    function OnNewPreSleepWarning(s,src,evt)
      s.InvokeUserCallbackFcn(s.NewPreSleepWarningFcn,s,[],'NewPreSleepWarningFcn');
    end
    function OnNewMacroMarkers(s,src,evt)
      s.InvokeUserCallbackFcn(s.NewMacroMarkersFcn,s,[],'NewMacroMarkersFcn');
    end
    function OnNewCollisionDetected(s,src,evt)
      s.InvokeUserCallbackFcn(s.NewCollisionDetectedFcn,s,[],'NewCollisionDetectedFcn');
    end
    function OnNewOrbBasicMessage(s,src,evt)
      s.InvokeUserCallbackFcn(s.NewOrbBasicMessageFcn,s,[],'NewOrbBasicMessageFcn');
    end
    function OnNewSelfLevelResult(s,src,evt)
      s.InvokeUserCallbackFcn(s.NewSelfLevelResultFcn,s,[],'NewSelfLevelResultFcn');
    end
    function OnNewGyroAxisLimitExceeded(s,src,evt)
      s.InvokeUserCallbackFcn(s.NewGyroAxisLimitExceededFcn,s,[],'NewGyroAxisLimitExceededFcn');
    end
    function OnNewSpheroSoulData(s,src,evt)
      s.InvokeUserCallbackFcn(s.NewSpheroSoulDataFcn,s,[],'NewSpheroSoulDataFcn');
    end
    function OnNewLevelUp(s,src,evt)
      s.InvokeUserCallbackFcn(s.NewLevelUpFcn,s,[],'NewLevelUpFcn');
    end
    function OnNewShieldDamage(s,src,evt)
      s.InvokeUserCallbackFcn(s.NewShieldDamageFcn,s,[],'NewShieldDamageFcn');
    end
    function OnNewXpUpdate(s,src,evt)
      s.InvokeUserCallbackFcn(s.NewXpUpdateFcn,s,[],'NewXpUpdateFcn');
    end
    function OnNewBoostUpdate(s,src,evt)
      s.InvokeUserCallbackFcn(s.NewBoostUpdateFcn,s,[],'NewBoostUpdateFcn');
    end
    
  end
  
  methods (Access = public)
    
    %% === API Core Device ================================================
    function fail = Ping(s,...
        reset_timeout_flag)
      % Ping  Pings the device - returns true is successful
      %   Use this method as a communications test.
      %
      %   Usage:
      %     fail = s.Ping()
      %       Returns false if Ping was successful.
      % DONE
      if nargin < 2
        reset_timeout_flag = [];
      end
      
      did = s.DID_CORE;
      cid = s.CMD_PING;
      data = [];
      % override answer_flag so this always provides a response
      fail = s.WriteClientCommandPacket(did,cid,data,...
        reset_timeout_flag,true);
    end
    
    function [fail,version_info] = GetVersioning(s,...
        reset_timeout_flag)
      % GetVersioning  Get version information from Sphero firmware.
      %   The Get Versioning command returns a whole slew of software and
      %   hardware information. It’s useful if your Client Application
      %   requires a minimum version number of some resource within Sphero
      %   in order to operate. The data record structure is comprised of
      %   fields for each resource that encodes the version number
      %   according to the specified format.
      %
      % Errata:
      %   The length of this data payload appears to be 8 bytes
      %
      % Properties:
      %   version_info
      %     This property is identical to the output version_info
      %
      % Outputs:
      %   version_info
      %     This is a struct with fields representing various version
      %     information.
      %   version_info.RECV
      %     This record version number, currently set to 02h. This will
      %     increase when more resources are added.
      %   version_info.MDL
      %     Model number; currently 02h for Sphero
      %   version_info.HW
      %     Hardware version code (ranges 1 through 9)
      %   version_info.MSA_ver
      %     Main Sphero App. version
      %   version_info.MSA_rev
      %     Main Sphero App. revision
      %   version_info.BL
      %     Bootloader version in packed nibble format (i.e. 32h is
      %     version 3.2)
      %   version_info.BAS
      %     orbBasic version in packed nibble format (i.e. 4.4)
      %   version_info.MACRO
      %     Macro executive version in packed nibble format (4.4)
      %
      % Examples:
      %   TODO
      
      if nargin < 2
        reset_timeout_flag = [];
      end
      
      did = s.DID_CORE;
      cid = s.CMD_VERSION;
      data = [];
      % override answer_flag so this always provides a response
      [fail,data] = s.WriteClientCommandPacket(did,cid,data,...
        reset_timeout_flag,true);
      
      version_info = [];
      if fail || isempty(data) || (8 ~= length(data))
        fail = true;
        return;
      end
      
      % process response data
      recv = data(1);
      mdl = data(2);
      hw =  data(3);
      msa_ver = data(4);
      msa_rev = data(5);
      bl = bitand(bitshift(data(6),-4),15,'uint8') + ...
        + 0.1 * bitand(data(6),15,'uint8');
      bas = ...
        bitand(bitshift(data(7),-4),15,'uint8') + ...
        + 0.1 * bitand(data(7),15,'uint8');
      macro = ...
        bitand(bitshift(data(8),-4),15,'uint8') + ...
        + 0.1 * bitand(data(8),15,'uint8');
      
      s.version_info.RECV     = recv;
      s.version_info.MDL      = mdl;
      s.version_info.HW       = hw;
      s.version_info.MSA_ver  = msa_ver;
      s.version_info.MSA_rev  = msa_rev;
      s.version_info.BL       = bl;
      s.version_info.BAS      = bas;
      s.version_info.MACRO    = macro;
      
      version_info = s.version_info;
      
    end
    
    
    function fail = ControlUARTTxLine(s,flag,...
        reset_timeout_flag)
      % ControlUARTTxLine  TODO
      %   This is a factory command that either enables or disables the
      %   CPU's UART transmit line so that another physically connected
      %   client can configure the Bluetooth module. The receive line is
      %   always listening, which is how you can re-enable the Tx line
      %   later. Or just reboot as this setting is not persistent.
      %
      % TODO
      assert( (nargin>=2),...
        'Input ''flag'' is required.');
      if nargin < 3
        reset_timeout_flag = [];
      end
      assert( islogical(flag) && isscalar(flag),...
        'Input ''flag'' must be a logical scalar.');
      
      flag = uint8(flag);
      
      did = s.DID_CORE;
      cid = s.CMD_CONTROL_UART_TX;
      data = flag;
      
      fail = s.WriteClientCommandPacket(did,cid,data,...
        reset_timeout_flag,true);
      
    end
    
    function fail = SetDeviceName(s,name,...
        reset_timeout_flag,answer_flag)
      % SetDeviceName  Change Sphero name.
      %   This formerly reprogrammed the Bluetooth module to advertise with
      %   a different name, but this is no longer the case. This assigned
      %   name is held internally and produced as part of the Get Bluetooth
      %   Info service below. Names are clipped at 48 characters in length
      %   to support UTF-8 sequences; you can send something longer but the
      %   extra will be discarded. This field defaults to the Bluetooth
      %   advertising name. To alter the Bluetooth advertising name from
      %   the standard Sphero-RGB pattern you will need to $$$ into the
      %   RN-42 within 60 seconds after power up, issue the command
      %   SN,mynewname and finish with r,1 to reboot the module.
      %
      % Inputs:
      %   name
      %     New Sphero name between 1 and 48 characters in length.
      %
      % TODO
      
      assert( nargin>=2,...
        'Input ''name'' is required.');
      if nargin < 3
        reset_timeout_flag = [];
      end
      if nargin < 4
        answer_flag = [];
      end
      
      assert(ischar(name)&&isvector(name)&&(length(name)>=1)&&(length(name)<=48),...
        'Input ''name'' must be a string of length in [1,48] characters.');
      
      name_bytes = uint8(name);
      
      did = s.DID_CORE;
      cid = s.CMD_SET_BT_NAME;
      data = name_bytes;
      
      fail = s.WriteClientCommandPacket(did,cid,data,...
        reset_timeout_flag,answer_flag);
    end
    
    function [fail,bluetooth_info] = GetBluetoothInfo(s,...
        reset_timeout_flag)
      % GetBluetoothInfo  Get Sphero's name and ID colors.
      %   This returns a structure containing the textual name in ASCII of
      %   the ball (defaults to the Bluetooth advertising name but can be
      %   changed), the Bluetooth address in ASCII and the ID colors the
      %   ball blinks when not connected to a smartphone. The ASCII name
      %   field is padded with zeros to its maximum size. This is provided
      %   as a courtesy for Clients that have don’t have a method to
      %   interrogate their underlying Bluetooth stack for this
      %   information.
      %
      % Properties:
      %   bluetooth_info
      %     This is a struct identical to the output bluetooth_info
      %     described below.
      %
      % Outputs:
      %   bluetooth_info
      %     TODO
      
      
      if nargin < 2
        reset_timeout_flag = [];
      end
      
      did = s.DID_CORE;
      cid = s.CMD_GET_BT_NAME;
      data = [];
      
      [fail,data] = s.WriteClientCommandPacket(did,cid,data,...
        reset_timeout_flag,true);
      
      bluetooth_info = [];
      if fail || isempty(data) || (32 ~= length(data))
        fail = true;
        return;
      end
      
      
      name = char(data(1:16));
      s.bluetooth_info.name = name(1:find(name,1,'last'));
      addr = char(data(17:28));
      s.bluetooth_info.address = [sprintf('%c%c:',addr(1:10)),addr(11:12)];
      % 29 should be zero
      s.bluetooth_info.rgb = char(data(30:32));
      
      bluetooth_info = s.bluetooth_info;
      
    end
    
    function fail = SetAutoReconnect(s,flag,time,...
        reset_timeout_flag)
      % Set Auto Reconnect  Configure autoreconnect feature.
      %   This configures the control of the Bluetooth module in its
      %   attempt to automatically reconnect with the last mobile Apple
      %   device. This is a courtesy behavior since the Apple Bluetooth
      %   stack doesn't initiate automatic reconnection on its own. The two
      %   parameters are simple: flag is 00h to disable or 01h to enable,
      %   and time is the number of seconds after power-up in which to
      %   enable auto reconnect mode. For example, if time = 30 then the
      %   module will be attempt reconnecting 30 seconds after waking up.
      %   (refer to RN-APL-EVAL pg. 7 for more info)
      assert( (nargin>=2),...
        'Input ''flag'' is required.');
      if nargin < 3
        assert(flag,...
          'Input ''time'' is required when ''flag'' is set.');
        time = 0; % flag is not set, time is arbitrarily zero
      end
      if nargin < 4
        reset_timeout_flag = [];
      end
      
      assert( islogical(flag) && isscalar(flag),...
        'Input ''flag'' must be a logical scalar.');
      assert(isnumeric(time)&&isscalar(time)&&(time>=0)&&(time<=intmax('uint8')),...
        'Input ''time'' must be a numeric scalar in [0,255] seconds.');
      
      did = s.DID_CORE;
      cid = s.CMD_SET_AUTO_RECONNECT;
      data = [flag,time];
      
      fail = s.WriteClientCommandPacket(did,cid,data,...
        reset_timeout_flag,true);
      
    end
    
    function [fail,autoreconnect_info] = GetAutoReconnect(s,...
        reset_timeout_flag)
      % GetAutoReconnect  Get configuration of autoreconnect feature.
      %
      % Properties:
      %   autoreconnect_info
      %     This struct is identical to the autoreconnect_info output
      %     described below.
      %
      % Outputs:
      %   autoreconnect_info
      %     Holds information about the autoreconnect feature
      %     configuration.
      %   autoreconnect_info.flag
      %     Logical scalar representing the feature enable state
      %   autoreconnect_info.time
      %     Numeric scalar representing the duration between reconnect
      %     attempts in seconds.
      %
      % DONE
      
      if nargin < 2
        reset_timeout_flag = [];
      end
      
      did = s.DID_CORE;
      cid = s.CMD_GET_AUTO_RECONNECT;
      data = [];
      
      [fail,data] = s.WriteClientCommandPacket(did,cid,data,...
        reset_timeout_flag,true);
      
      autoreconnect_info = [];
      if fail || isempty(data) || (xx~=length(data))
        fail = true;
        return;
      end
      
      s.autoreconnect_info.flag = data(1)==1;
      s.autoreconnect_info.time = double(data(2));
      
      autoreconnect_info = s.autoreconnect_info;
      
    end
    
    function [fail,power_state_info] = GetPowerState(s,...
        reset_timeout_flag)
      % GetPowerState  TODO
      %   This returns the current power state and some additional
      %   parameters to the Client. They are detailed below.
      %
      % Properties
      %   power_state_info
      %     Identical to power_state_info output described below
      %
      % Outputs:
      %   power_state_info
      %     TODO
      %   power_state_info.rec_ver
      %     TODO
      %   power_state_info.power
      %     TODO
      %   power_state_info.batt_voltage
      %     TODO
      %   power_state_info.num_charges
      %     TODO
      %   power_state_info.time_since_charge
      %     TODO
      
      if nargin < 2
        reset_timeout_flag = [];
      end
      
      did = s.DID_CORE;
      cid = s.CMD_GET_PWR_STATE;
      data = [];
      
      [fail,data] = s.WriteClientCommandPacket(did,cid,data,...
        reset_timeout_flag,true);
      
      power_state_info = [];
      if fail || isempty(data) || (8~=length(data))
        fail = true;
        return;
      end
      
      s.power_state_info.rec_ver = double(data(1));
      power_enum = double(data(2));
      switch power_enum
        case 1
          s.power_state_info.power = 'charging';
        case 2
          s.power_state_info.power = 'ok';
        case 3
          s.power_state_info.power = 'low';
        case 4
          s.power_state_info.power = 'critical';
        otherwise
          warning('Unknown power state.');
          s.power_state_info.power = 'unknown';
      end
      
      s.power_state_info.batt_voltage = ...
        0.01 * double(s.IntegerFromByteArray(data(3:4),'uint16'));
      s.power_state_info.num_charges = ...
        double(s.IntegerFromByteArray(data(5:6),'uint16'));
      s.power_state_info.time_since_charge = ...
        double(s.IntegerFromByteArray(data(7:8),'uint16'));
      
      power_state_info = s.power_state_info;
      
    end
    
    function fail = SetPowerNotification(s,flag,...
        reset_timeout_flag,answer_flag)
      % SetPowerNotification  Turn asynchronous power notifications on/off.
      %   The message handler for these messages isn't developed yet.
      %
      % TODO implement built-in handling for this async response message
      
      if nargin < 2
        % input required
        return;
      end
      if nargin < 3
        reset_timeout_flag = [];
      end
      if nargin < 4
        answer_flag = [];
      end
      
      if flag
        flag = 1;
      else
        flag = 0;
      end
      
      did = s.DID_CORE;
      cid = s.CMD_SET_PWR_NOTIFY;
      data = flag;
      
      fail = s.WriteClientCommandPacket(did,cid,data,...
        reset_timeout_flag,answer_flag);
      
    end
    
    
    function fail = Sleep(s,wakeup,macro,orb_basic,...
        reset_timeout_flag)
      % Sleep  Put Sphero to sleep immediately
      %   This command puts Sphero to sleep immediately. There are three
      %   optional parameters that program the robot for future actions
      %
      %   Inputs:
      %     wakeup (optional)
      %       The number of seconds for Sphero to sleep for and then
      %       automatically reawaken. Zero does not program a wakeup
      %       interval, so he sleeps forever. FFFFh attempts to put him
      %       into deep sleep (if supported in hardware) and returns an
      %       error if the hardware does not support it.
      %     macro (optional)
      %       If non-zero, Sphero will attempt to run this macro ID upon
      %       wakeup.
      %     orb_basic (optional)
      %       If non-zero, Sphero will attempt to run an orbBasic program
      %       in Flash from this line number.
      
      if nargin < 2
        wakeup = 0;
      end
      if nargin < 3 || isempty(macro)
        macro = 0;
      end
      if nargin < 4 || isempty(orb_basic)
        orb_basic = 0;
      end
      if nargin < 5
        reset_timeout_flag = [];
      end
      
      % check valid input
      assert(isnumeric(wakeup)&&isscalar(wakeup)&&(wakeup>=0)&&(wakeup<=intmax('uint16')),...
        'Input ''wakeup'' must be a scalar in [0,65535] seconds.');
      wakeup = round(wakeup);
      
      % translate data format
      wakeup = s.ByteArrayFromInteger(wakeup,'uint16');
      macro = s.ByteArrayFromInteger(macro,'uint8');
      orb_basic = s.ByteArrayFromInteger(orb_basic,'uint16');
      
      did = s.DID_CORE;
      cid = s.CMD_SLEEP;
      data = [wakeup,macro,orb_basic];
      
      fail = s.WriteClientCommandPacket(did,cid,data,...
        reset_timeout_flag,true);
      
    end
    
    function [fail,voltage_trip_points] = GetVoltageTripPoints(s,...
        reset_timeout_flag)
      % GetVoltageTripPoints  TODO
      %   This returns the voltage trip points for what Sphero considers
      %   Low battery and Critical battery. The values are expressed in
      %   100ths of a volt, so the defaults of 7.00V and 6.50V respectively
      %   are returned as 700 and 650.
      %
      %   Outputs:
      %     voltage_trip_points
      %       TODO
      %     voltage_trip_points.vlow
      %       TODO
      %     voltage_trip_points.vcrit
      %       TODO
      %
      %   Usage:
      %     [~,vlow,vcrit] = s.GetVoltageTripPoints()
      %       TODO
      
      if nargin < 3
        reset_timeout_flag = [];
      end
      
      did = s.DID_CORE;
      cid = s.GET_POWER_TRIPS;
      data = [];
      
      [fail,data] = s.WriteClientCommandPacket(did,cid,data,...
        reset_timeout_flag,true);
      
      voltage_trip_points = [];
      if fail || isempty(data) || (4~=length(data))
        fail = true;
        return;
      end
      
      voltage_trip_points.vlow = ...
        0.01 * double(s.IntegerFromByteArray(data(1:2),'uint16'));
      voltage_trip_points.vcrit = ...
        0.01 * double(s.IntegerFromByteArray(data(3:4),'uint16'));
      
    end
    
    function fail = SetVoltageTripPoints(s,vlow,vcrit,...
        reset_timeout_flag)
      % SetVoltageTripPoints  TODO
      %   This assigns the voltage trip points for low and critical battery
      %   voltages. The values are specified in 100ths of a volt and the
      %   limitations on adjusting these away from their defaults are:
      %
      %   * vlow must be in the range 675 to 725 (±25)
      %   * vcrit must be in the range 625 to 675 (±25)
      %   * There must be 0.25V of separation between the two values
      %
      %   Shifting these values too low could result in very little warning
      %   before Sphero forces himself to sleep, depending on the age and
      %   history of the battery pack. So be careful.
      %
      %   Inputs:
      %     vlow
      %       TODO
      %     vcrit
      %       TODO
      %
      %   Usage:
      %     s.SetVoltageTripPoints()
      %       TODO Sets defaults
      %
      %     s.SetVoltageTripPoints(vlow,vcrit)
      %       TODO
      
      assert(nargin>=3,...
        'Inputs ''vlow'' and ''vcrit'' are required.');
      if nargin < 4
        reset_timeout_flag = [];
      end
      
      assert(isnumeric(vlow)&&isscalar(vlow)&&(vlow>=6.75)&&(vlow<=7.25),...
        'Input ''vlow'' must be a numeric scalar in [6.75,7.25] volts.');
      assert(isnumeric(vcrit)&&isscalar(vcrit)&&(vcrit>=6.25)&&(vcrit<=6.75),...
        'Input ''vcrit'' must be a numeric scalar in [6.25,6.75] volts.');
      assert((vlow-vcrit)>=0.25,...
        'The difference in input values vlow-vcrit must be at least 0.25 volts.');
      
      vlow = s.ByteArrayFromInteger(round(100*vlow),'uint16');
      vcrit = s.ByteArrayFromInteger(round(100*vcrit),'uint16');
      
      did = s.DID_CORE;
      cid = s.SET_POWER_TRIPS;
      data = [vlow,vcrit];
      
      fail = s.WriteClientCommandPacket(did,cid,data,...
        reset_timeout_flag,true);
      
    end
    
    function fail = SetInactivityTimeout(s,timeout,...
        reset_timeout_flag)
      % SetInactivityTimeout  Set sleep timeout in seconds
      %   To save battery power, Sphero normally goes to sleep after a
      %   period of inactivity. From the factory this value is set to 600
      %   seconds (10 minutes) but this API command can alter it to any
      %   value of 60 seconds or greater. The inactivity timer is reset
      %   every time an API command is received over Bluetooth or a shell
      %   command is executed in User Hack mode. In addition, the timer is
      %   continually reset when a macro is running unless the MF_STEALTH
      %   flag is set, and the same for orbBasic unless the BF_STEALTH flag
      %   is set.
      %
      % Inputs:
      %   timeout (optional)
      %     Inactivity timeout in [60,65535] seconds.
      %
      % Usage:
      %   s.SetInactivityTimeout()
      %     Sets inactivity timeout to the default value, 600 seconds.
      %
      %   s.SetInactivityTimeout(2718)
      %     Sets inactivity timeout to 2718 seconds (45 minutes and 18
      %     seconds).
      
      if nargin < 2
        timeout = 600;
      end
      if nargin < 3
        reset_timeout_flag = [];
      end
      
      assert(isnumeric(timeout)&&isscalar(timeout)&&(timeout>=60)&&(timeout<=(2^16-1)),...
        sprintf('Input timeout must be a numeric scalar in [60,%d] seconds.',intmax('uint16')));
      timeout = round(timeout);
      
      timeout = s.ByteArrayFromInteger(timeout,'uint16');
      
      did = s.DID_CORE;
      cid = s.SET_INACTIVE_TIMER;
      data = timeout;
      
      fail = s.WriteClientCommandPacket(did,cid,data,...
        reset_timeout_flag,true);
      
    end
    
    function JumpToBootloader(s)
      % JumpToBootloader  NOT IMPLEMENTED
      %   This command requests a jump into the Bootloader to prepare for a
      %   firmware download. It always succeeds, because you can always
      %   stop where you are, shut everything down and transfer execution.
      %   All commands after this one must comply with the Bootloader
      %   Protocol Specification, which is a separate document.
      %
      %   Note that just because you can always vector into the Bootloader,
      %   it doesn't mean you can get anything done. Further details are
      %   explained in the associated document but in short: the Bootloader
      %   doesn't implement the entire Core Device message set and if the
      %   battery is deemed too low to execute reflashing operations, all
      %   you can do is return to the Main Application.
      error('JumpToBootloader is not implemented');
    end
    
    function fail = PerformLevel1Diagnostics(s,...
        reset_timeout_flag)
      % PerformLevel1Diagnostics
      %   This is a developer-level command to help diagnose aberrant
      %   behavior. Most system counters, process flags, and system states
      %   are decoded into human readable ASCII. There are two responses to
      %   this command: a Simple Response followed by a large async message
      %   containing the results of the diagnostic tests. As of FW version
      %   0.99, the answer was well over 1K in length.
      %
      %   The diagnostic message is printed to the command window as well
      %   as a text file in the current folder as indicated as indicated in
      %   the command window output.
      
      if nargin < 2
        reset_timeout_flag = [];
      end
      
      did = s.DID_CORE;
      cid = s.CMD_RUN_L1_DIAGS;
      data = [];
      
      [fail] = s.WriteClientCommandPacket(did,cid,data,...
        reset_timeout_flag,true);
      
      
      
    end
    
    function [fail,data] = PerformLevel2Diagnostics(s,...
        reset_timeout_flag)
      % PerformLevel2Diagnostics
      %   This is a developers-only command to help diagnose aberrant
      %   behavior. It is much less informative than the Level 1 command
      %   but it is in binary format and easier to parse. Here is the
      %   layout of the data record which is currently 58h bytes long
      
      did = s.DID_CORE;
      cid = s.CMD_RUN_L2_DIAGS;
      data = [];
      
      [fail,data] = s.WriteClientCommandPacket(did,cid,data,...
        reset_timeout_flag,true);
      
      if fail || isempty(data) || (88 ~= length(data))
        fail = true;
        return;
      end
      
      s.disp_level2diagnostics(data);
      
    end
    
    function fail = ClearCounters(s,...
        reset_timeout_flag)
      % ClearCounters  TODO
      %   This is a developers-only command to clear the various system
      %   counters described in command 41h. It is denied when Sphero is in
      %   Normal mode.
      
      if nargin < 2
        reset_timeout_flag = [];
      end
      
      did = s.DID_CORE;
      cid = s.CMD_CLEAR_COUNTERS;
      data = [];
      
      fail = s.WriteClientCommandPacket(did,cid,data,...
        reset_timeout_flag,true);
      
    end
    
    function fail = AssignTimeValue(s,sphero_time,...
        reset_timeout_flag)
      % AssignTimeValue  Set Sphero's system clock timer.
      %   Sphero contains a 32-bit counter that increments every
      %   millisecond. It has no absolute temporal meaning, just a relative
      %   one. This command assigns the counter a specific value for
      %   subsequent sampling. Though it starts at zero when Sphero wakes
      %   up, assigning it too high of a value with this command could
      %   cause it to roll over.
      %
      %   Inputs:
      %     sphero_time (required)
      %       Time to assign to Sphero's counter, specified in seconds.
      %
      %   Usage:
      %     s.AssignTimeValue(2.718)
      %       Sets Sphero's clock to 2718 milliseconds.
      assert(nargin>=2,...
        'Input ''sphero_time'' is required.');
      if nargin < 3
        reset_timeout_flag = [];
      end
      
      assert(isnumeric(sphero_time)&&isscalar(sphero_time)&&(sphero_time>=0)&&(sphero_time<=intmax('uint32')),...
        sprintf('Input sphero_time must be a numeric scalar in [0,%f] seconds.',double(intmax('uint32'))/1000));
      
      sphero_time = round(sphero_time*1000);
      
      did = s.DID_CORE;
      cid = s.CMD_ASSIGN_TIME;
      data = s.ByteArrayFromInteger(sphero_time,'uint32');
      
      fail = s.WriteClientCommandPacket(did,cid,data,...
        reset_timeout_flag,true);
      
    end
    
    function fail = PollPacketTimes(s,reset_timeout_flag)
      % PollPacketTimes  Profile network transport times.
      %   This command helps the Client application profile the
      %   transmission and processing latencies in Sphero so that a
      %   relative synchronization of timebases can be performed. This
      %   technique is based upon the scheme in the Network Time Protocol
      %   (RFC 5905) and allows the Client to reconcile time stamped
      %   messages from Sphero to its own time stamped events. In the
      %   following discussion, each 32-bit value is a count of
      %   milliseconds from some reference within the device.
      %
      %   The scheme is as follows: the Client sends the command
      %   with the Client Tx time (T1) filled in. Upon receipt of the packet,
      %   the command processor in Sphero copies that time into the response
      %   packet and places the current value of the millisecond counter into
      %   the Sphero Rx time field (T2). Just before the transmit engine
      %   streams it into the Bluetooth module, the Sphero Tx time value (T3)
      %   is filled in. If the Client then records the time at which the
      %   response is received (T4) the relevant time segments can be
      %   computed from the four time stamps T1-T4:
      %
      %   * The value offset represents the maximum-likelihood time offset of
      %   the Client clock to Sphero's system clock. offset = 1/2 * [(T2 -
      %   T1) + (T3 - T4)]
      %   * The value delay represents the round-trip delay between the
      %   Client and Sphero: delay = (T4 - T1) - (T3 - T2)
      %
      %   Properties:
      %     network_time
      %       This is a struct with fields offset and delay containing
      %       these values as described above in seconds.
      
      if nargin < 2
        reset_timeout_flag = [];
      end
      
      client_time = round(s.time_since_init*1000); % millis
      
      did = s.DID_CORE;
      cid = s.CMD_POLL_TIMES;
      data = s.ByteArrayFromInteger(client_time,'uint32');
      
      [fail,data] = s.WriteClientCommandPacket(did,cid,data,...
        reset_timeout_flag,true);
      
      client_rx_time = round(s.time_since_init*1000); % millis
      
      if isempty(data) || (12 ~= length(data))
        fail = true;
        return;
      end
      
      client_tx_time = double(s.IntegerFromByteArray(data(1:4),'uint32'));
      sphero_rx_time = double(s.IntegerFromByteArray(data(5:8),'uint32'));
      sphero_tx_time = double(s.IntegerFromByteArray(data(9:12),'uint32'));
      
      if client_time ~= client_tx_time
        warning('Echoed client tx time mismatch.');
      end
      
      ct = client_tx_time;
      cr = client_rx_time;
      st = sphero_tx_time;
      sr = sphero_rx_time;
      
      offset = 0.5 * ( (sr-ct) + (st-cr) );
      
      delay = (cr-ct) - (st-sr); % total network delay
      
      s.network_time.offset = offset/1000;
      s.network_time.delay = delay/1000;
      
    end
    
    
    %% === API Sphero Device ==============================================
    function fail = SetHeading(s,heading,...
        reset_timeout_flag,answer_flag)
      % SetHeading  Command a new heading (planar orientation)
      %   This allows the smartphone client to adjust the orientation of
      %   Sphero by commanding a new reference heading in degrees, which
      %   ranges from 0 to 359 (here, any heading value is adjuted to this
      %   range automatically). You will see the ball respond immediately
      %   to this command if stabilization is enabled. In FW version 3.10
      %   and later this also clears the maximum value counters for the
      %   rate gyro, effectively re-enabling the generation of an async
      %   message alerting the client to this event.
      
      if nargin < 2
        return;
      end
      if nargin < 3
        reset_timeout_flag = [];
      end
      if nargin < 4
        answer_flag = [];
      end
      
      heading = floor(wrapTo360(heading));
      heading_arr = s.ByteArrayFromInteger(heading,'uint16');
      
      did = s.DID_SPHERO;
      cid = s.CMD_SET_CAL; % what a weird alias for this command
      data = heading_arr;
      
      fail = s.WriteClientCommandPacket(did,cid,data,...
        reset_timeout_flag,answer_flag);
      
    end
    
    function fail = SetStabilization(s,flag,...
        reset_timeout_flag,answer_flag)
      % SetStabilization  Turns on or off internal stabilization
      %   The IMU is used to match the ball's orientation to its various
      %   set points. Stabilization is enabled by default when Sphero
      %   powers up. You will want to disable stabilization when using
      %   Sphero as an external input controller or even to save battery
      %   power during testing that doesn't involve movement (orbBasic,
      %   etc.) An error is returned if the sensor network is dead; without
      %   sensors the IMU won't operate and thus there is no feedback to
      %   control stabilization.
      
      if nargin < 2
        return;
      end
      if nargin < 3
        reset_timeout_flag = [];
      end
      if nargin < 4
        answer_flag = [];
      end
      
      if flag
        flag = 1;
      else
        flag = 0;
      end
      
      did = s.DID_SPHERO;
      cid = s.CMD_SET_STABILIZ;
      data = flag;
      
      fail = s.WriteClientCommandPacket(did,cid,data,...
        reset_timeout_flag,answer_flag);
      
    end
    
    function fail = SetRotationRate(s,rate,...
        reset_timeout_flag,answer_flag)
      % SetRotationRate  Command angular speed for orientation changes
      %   This allows you to control the rotation rate that Sphero will use
      %   to meet new heading commands. A lower value offers better control
      %   but with a larger turning radius. A higher value will yield quick
      %   turns but Sphero may roll over on itself and lose control. The
      %   commanded value is in units of 0.784 degrees/sec. So, setting a
      %   value of C8h will set the rotation rate to 157 degrees/sec. A
      %   value of 255 jumps to the maximum (currently 400 degrees/sec). A
      %   value of zero doesn't make much sense so it's interpreted as 1,
      %   the minimum.
      
      if nargin < 2
        return;
      end
      if nargin < 3
        reset_timeout_flag = [];
      end
      if nargin < 4
        answer_flag = [];
      end
      
      if rate > 1 || rate < 0
        return;
      end
      
      rate = round(rate*255);
      
      did = s.DID_SPHERO;
      cid = s.CMD_SET_ROTATION_RATE;
      data = rate;
      
      fail = s.WriteClientCommandPacket(did,cid,data,...
        reset_timeout_flag,answer_flag);
      
    end
    
    function GetChassisID(s)
      % GetChassisID
      error('GetChassisID is not implemented.');
    end
    
    function SelfLevel(s)
      % SelfLevel
      error('SelfLevel is not implemented.')
    end
    
    function fail = SetDataStreaming(...
        s,frame_rate,frame_count,packet_count,sensors_spec,...
        reset_timeout_flag)
      % SetDataStreaming  Stream sensor data asynchronously.
      %
      %
      %   Inputs:
      %     frame_rate    Desired sampling rate for data frames
      %     frame_count   Number of sample frames emitted per packet
      %                   Hint: frame_rate/frame_count is the rate at which
      %                   packets are transmitted asynchronously
      %     packet_count  Packet count 1-255 (or 0 for unlimited streaming)
      %     sensors_spec  Cell string of sensor groups to stream. Passing
      %                   sensors_spec = {''} disables data streaming.
      %
      %   Sensor group strings:
      %     accel_raw
      %     gyro_raw
      %     motor_emf_raw
      %     motor_pwm_raw
      %     imu_rpy_filt
      %     accel_filt
      %     gyro_filt
      %     motor_emf_filt
      %     quat
      %     odo
      %     accel_one
      %     vel
      %
      %   Example arguments for sensor_spec:
      %     sensor_spec = {'accel_one'}         Selects magnitude of
      %                                         measured linear
      %                                         acceleration
      %     sensor_spec = {'accel_raw','quat'}  Select raw measured linear
      %                                         acceleration and
      %                                         quaternion
      %     sensor_spec = {'accel_one'}         Selects nothing --
      %                                         Disables data streaming
      %
      % Here's an example with frame_rate = 50 with frame_count set to
      % either 1 or 2.
      %
      % Sphero system ticks at 400[Hz] (below)
      % +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      % +---------------+---------------+---------------+---------------+
      % Frame sampling ticks at 50[Hx] (above)
      %
      % The resulting data frames are always sampled on the frame_rate
      % ticks. Here, samples of the data frame are shown with '#'
      % #---------------#---------------#---------------#---------------#
      %
      % But frame_count determines how the frames are stuffed into packets
      % before being sent over the wire ...
      %
      % With frame_count = 1 ...
      %  -- packet 1 --| -- packet 2 --| -- packet 3 --| -- packet 4 --|
      % #---------------#---------------#---------------#---------------#
      % ... the packets stream in at the frame_rate 50[Hz] with one frame
      % of data per asynchronous message.
      %
      % With frame_count = 2 ...
      %  ---------- packet 1 ----------| ---------- packet 2 ----------|
      % #---------------#---------------#---------------#---------------#
      % ... the packets stream in at 25[Hz] (half of the frame_rate) with
      % two frames of data per asynchronous message.
      %
      % Known limitations
      %   The effective bandwidth of Matlab and the system its running on
      %   is NOT UNLIMITED! That is, there are limits to how much data you
      %   can stream and how fast. The frame_rate and packet_count must be
      %   chosen so that your system can keep up with the incoming
      %   messages.
      %
      %   When problems arise, they may be indicated by synchronous command
      %   failures (timeouts). This may be due to excessive lag in Matlab
      %   reading the incoming data buffer and/or the dropping of at least
      %   one BytesAvailableFcn event. If the latter occurs, recovery may
      %   be possible by manually reading the stale bytes by calling
      %   fread(s.bt,s.bt.BytesAvailable),
      
      if nargin < 5
        % not enough inputs (all inputs required)
        return;
      end
      if nargin < 6
        reset_timeout_flag = [];
      end
      
      if frame_rate > s.SPHERO_CONTROL_SYSTEM_RATE
        s.DEBUG_PRINT('Data streaming frame_rate too high, setting to maximum: %d [Hz].',...
          s.SPHERO_CONTROL_SYSTEM_RATE);
        frame_rate = s.SPHERO_CONTROL_SYSTEM_RATE;
      elseif frame_rate <= 0
        % bad sample rate
        s.DEBUG_PRINT('Data streaming frame_rate must be positive.');
        return;
      end
      
      prev_info = s.data_streaming_info;
      
      % compute sample rate divider
      % frame_rate = SPHERO_CONTROL_SYSTEM_RATE/n
      n = ceil(s.SPHERO_CONTROL_SYSTEM_RATE/frame_rate); %
      n_arr = s.ByteArrayFromInteger(n,'uint16');
      
      % max value of frame_count bounded by uint16 data length variable in
      % the response message
      % (2^16-2) is max length of dlen - 1 (for checksum)
      % 60 is max bytes of streaming data
      if frame_count > (2^16-2)/60
        % frame_count enormous... maybe Sphero would even run out of
        % memory... lol
        s.DEBUG_PRINT('Data streaming frame_count too high.');
        return;
      elseif frame_count < 1
        % bad input
        s.DEBUG_PRINT('Data streaming frame_count must be positive.');
        return;
      end
      
      m_arr = s.ByteArrayFromInteger(frame_count,'uint16');
      
      pcnt = packet_count;
      
      s.SetDataStreamingSensors(sensors_spec);
      
      mask_arr = s.ByteArrayFromInteger(...
        s.data_streaming_info.mask,'uint32');
      mask2_arr = s.ByteArrayFromInteger(...
        s.data_streaming_info.mask2,'uint32');
      
      s.data_streaming_info.is_enabled = true;
      s.data_streaming_info.sample_time = ...
        n/s.SPHERO_CONTROL_SYSTEM_RATE;
      s.data_streaming_info.frame_rate = 1/n;
      s.data_streaming_info.frame_count = frame_count;
      s.data_streaming_info.packet_count = packet_count;
      s.data_streaming_info.num_samples = 0;
      
      % TODO input arguments
      did = s.DID_SPHERO;
      cid = s.CMD_SET_DATA_STREAMING;
      data = [n_arr,m_arr,mask_arr,pcnt,mask2_arr];
      
      fail = s.WriteClientCommandPacket(did,cid,data,...
        reset_timeout_flag,true);
      
      if fail
        s.data_streaming_info = prev_info;
        return;
      elseif isempty(s.data_streaming_info.sensors)
        s.data_streaming_info.is_enabled = false;
      end
      
    end
    
    function fail = ConfigureCollisionDetection(s,...
        meth,thresh,spd,dead,...
        reset_timeout_flag,answer_flag)
      % Configure Collision Detection
      
      if nargin < 2 || isempty(meth)
        % not enough inputs
        return;
      end
      if nargin < 3 || isempty(thresh)
        dead = s.COL_DET_THRESH_DEFAULT*[1,1];
      end
      if nargin < 4 || isempty(spd)
        dead = s.COL_DET_SPD_DEFAULT*[1,1];
      end
      if nargin < 5 || isempty(dead)
        dead = s.COL_DET_DEAD_DEFAULT;
      end
      if nargin < 6
        reset_timeout_flag = [];
      end
      if nargin < 7
        answer_flag = [];
      end
      
      assert(ischar(meth)&&any(strcmp(meth,{'off','one','two','three','four'})),...
        'Input ''meth'' must be a collision detection method string, ''off'', ''one'', ''two'', ''three'', or ''four''.');
      
      switch meth
        case 'off'
          meth = s.COL_DET_METHOD_OFF;
        case 'one'
          meth = s.COL_DET_METHOD_1;
        case 'two'
          meth = s.COL_DET_METHOD_2;
        case 'three'
          meth = s.COL_DET_METHOD_3;
        case 'four'
          meth = s.COL_DET_METHOD_4;
      end
      
      assert(isnumeric(thresh)&&isvector(thresh)&&(2==length(thresh))&&all(thresh>=0&thresh<=1),...
        'Input ''thresh'' must be a numeric 2 vector in [0,1].');
      if iscolumn(thresh), thresh = thresh'; end
      thresh = uint8(round(thresh*255));
      
      assert(isnumeric(spd)&&isvector(spd)&&(2==length(spd))&&all(spd>=0&spd<=1),...
        'Input ''spd'' must be a numeric 2 vector in [0,1].');
      if iscolumn(spd), spd = spd'; end
      spd = uint8(round(spd*255));
      
      assert(isnumeric(dead)&&isscalar(dead)&&(dead>=0)&&(dead<=2.55)&&all(dead>=0),...
        'Input ''dead'' must be a numeric scalar in [0,2.55] seconds.');
      dead = uint8(round(dead*100));
      
      did = s.DID_SPHERO;
      cid = s.CMD_SET_COLLISION_DET;
      data = [meth,thresh,spd,dead];
      
      fail = s.WriteClientCommandPacket(did,cid,data,...
        reset_timeout_flag,answer_flag);
      
      % set/unset enabled flag in info struct
      if ~fail
        if meth == s.COL_DET_METHOD_OFF
          s.collision_info.is_enabled = false;
        else
          s.collision_info.is_enabled = true;
        end
      end
      
    end
    
    function fail = ConfigureLocator(s,x,y,yaw_tare,flags,...
        reset_timeout_flag,answer_flag)
      % ConfigureLocator  Configure translation and rotation of Locator.
      %   Translate Sphero's Locator coordinate system to (x,y) and rotate
      %   by yaw_tare.
      
      if nargin < 4
        return;
      elseif nargin < 5
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
      
      yaw_tare = floor(wrapTo360(yaw_tare));
      if yaw_tare == 360, yaw_tare = 0; end
      x_arr = s.ByteArrayFromInteger(x,'int16');
      y_arr = s.ByteArrayFromInteger(y,'int16');
      yaw_tare_arr = s.ByteArrayFromInteger(yaw_tare,'int16');
      
      did = s.DID_SPHERO;
      cid = s.CMD_LOCATOR;
      data = [flags,x_arr,y_arr,yaw_tare_arr];
      
      fail = s.WriteClientCommandPacket(did,cid,data,...
        reset_timeout_flag,answer_flag);
      
    end
    
    function fail = SetAccelerometerRange(s,fsr,...
        reset_timeout_flag)
      % SetAccelerometerRange
      
      if nargin < 2
        return;
      elseif ~any(fsr == [2,4,8,16])
        return;
      end
      
      if nargin<3
        reset_timeout_flag = [];
      end
      
      range_idx = 2;
      
      switch fsr
        case 2
          range_idx = 0;
        case 4
          range_idx = 1;
        case 8
          range_idx = 2;
        case 16
          range_idx = 3;
        otherwise
          return;
      end
      
      did = s.DID_SPHERO;
      cid = s.CMD_SET_ACCELERO;
      data = range_idx;
      
      fail = s.WriteClientCommandPacket(did,cid,data,...
        reset_timeout_flag,true);
      
    end
    
    function fail = ReadLocator(s,...
        reset_timeout_flag)
      % ReadLocator  Read Locator data into local properties.
      %   After calling this method, inspect the odo, vel, and sog
      %   properties for Sphero's latest position, velocity, and speed.
      
      if s.data_streaming_info.is_enabled
        % don't mess with streaming data while streaming
        fail = true;
        return;
      end
      
      if nargin < 2
        reset_timeout_flag = [];
      end
      
      did = s.DID_SPHERO;
      cid = s.CMD_READ_LOCATOR;
      data = [];
      
      % override answer_flag
      [fail,data] = s.WriteClientCommandPacket(did,cid,data,...
        reset_timeout_flag,true);
      
      if fail || isempty(data)
        fail = true;
        return;
      end
      
      s.time = s.time_since_init;
      
      % process data
      x   = s.IntegerFromByteArray(data(1:2)  , 'int16');
      y   = s.IntegerFromByteArray(data(3:4)  , 'int16');
      dx  = s.IntegerFromByteArray(data(5:6)  , 'int16');
      dy  = s.IntegerFromByteArray(data(7:8)  , 'int16');
      v   = s.IntegerFromByteArray(data(9:10) ,'uint16');
      
      s.odo = [x;y];
      s.vel = [dx;dy];
      s.sog = v;
      
      fail = false;
      
    end
    
    function fail = SetRGBLEDOutput(s,rgb,flag,...
        reset_timeout_flag,answer_flag)
      % Set RGB LED Output  Change Sphero's color to rgb triple, rgb.
      %   Specify the new rgb color in a 3-vector of red, green, blue
      %   intensities in the range 0 to 1.
      
      if nargin < 2
        return;
      elseif nargin < 3
        flag = false;
      end
      
      if nargin < 5
        answer_flag = [];
      end
      if nargin < 4
        reset_timeout_flag = [];
      end
      
      if any(rgb<0) || any(rgb>1)
        return;
      end
      
      if flag
        flag = 1;
      else
        flag = 0;
      end
      
      rgb = round(255*rgb);
      
      red     = rgb(1);
      green   = rgb(2);
      blue    = rgb(3);
      
      did = s.DID_SPHERO;
      cid = s.CMD_SET_RGB_LED;
      data = [red,green,blue,flag];
      
      fail = s.WriteClientCommandPacket(did,cid,data,...
        reset_timeout_flag,answer_flag);
      
      if fail
        % failed
      else
        s.rgb = rgb/255;
      end
      
    end
    
    function fail = SetBackLEDOutput(s,bright,...
        reset_timeout_flag,answer_flag)
      % Set Back LED Output  Change intensity of Sphero's back LED
      %   Specify the brightness of the back LED with parameter bright in
      %   the range 0 to 1.
      
      if nargin < 2
        return;
      end
      if nargin < 3
        reset_timeout_flag = [];
      end
      if nargin < 4
        answer_flag = [];
      end
      
      if bright < 0 || bright > 1
        return;
      end
      
      bright = round(255*bright);
      
      did = s.DID_SPHERO;
      cid = s.CMD_SET_BACK_LED;
      data = bright;
      
      fail = s.WriteClientCommandPacket(did,cid,data,...
        reset_timeout_flag,answer_flag);
      
    end
    
    function fail = GetRGBLED(s,reset_timeout_flag)
      % GetRGBLED  Get the "user LED color"
      %   This retrieves the "user LED color" which is stored in the config
      %   block (which may or may not be actively driven to the RGB LED).
      
      
      error('GetRGBLED is not implemented.');
      
      if nargin < 2
        reset_timeout_flag = [];
      end
      
      did = s.DID_SPHERO;
      cid = s.CMD_GET_RGB_LED;
      data = [];
      
      [fail,data] = s.WriteClientCommandPacket(did,cid,data,...
        reset_timeout_flag,true);
      
      if fail || isempty(data)
        fail = true;
        return;
      end
      
      s.rgb_user = double(data)/255;
      
    end
    
    function fail = Roll(s,speed,heading,state,...
        reset_timeout_flag,answer_flag)
      % Roll  Make Sphero roll at speed and heading.
      %   Specify speed as percentage of max speed in the range 0 to 1.
      %   Heading is an angle in degrees. State can be 'normal', 'fast', or
      %   'stop'
      
      if nargin < 3
        return;
      end
      if nargin < 4 || isempty(state)
        state = 'normal';
      end
      if nargin < 5
        reset_timeout_flag = [];
      end
      if nargin < 6
        answer_flag = [];
      end
      
      if ~ischar(state)
        return;
      elseif ~any(strcmp({'normal','fast','stop'},state))
        return;
      elseif speed < 0 || speed > 1
        return;
      end
      
      % figure out go parameter from state
      go = 1;
      switch state
        case 'normal'
          go = 1;
        case 'fast'
          go = 2;
        case 'stop'
          go = 0;
        otherwise
          return;
      end
      
      speed = round(255*speed);
      
      heading = floor(wrapTo360(heading));
      if heading == 360, heading = 0; end
      heading_arr = s.ByteArrayFromInteger(heading,'int16');
      
      did = s.DID_SPHERO;
      cid = s.CMD_ROLL;
      data = [speed,heading_arr,go];
      
      fail = s.WriteClientCommandPacket(did,cid,data,...
        reset_timeout_flag,answer_flag);
      
    end
    
    function fail = Boost(s,state,...
        reset_timeout_flag,answer_flag)
      % Boost
      %   Beginning with FW 1.46 (S2) and 3.25 (S3), this executes the
      %   boost macro from within the SSB. It takes a 1 byte parameter
      %   which is either 01h to begin boosting or 00h to stop.
      
      fail = true;
      if nargin<2
        return;
      end
      if nargin<2
        reset_timeout_flag = [];
      end
      if nargin<3
        answer_flag = [];
      end
      
      if ~ischar(state) || ~any(strmp(state,{'on','off'}))
        return;
      end
      
      switch state
        case 'on'
          state = 1;
        case 'off'
          state = 0;
      end
      
      did = s.DID_SPHERO;
      cid = s.CMD_BOOST;
      data = state;
      
      fail = s.WriteClientCommandPacket(did,cid,data,...
        reset_timeout_flag,answer_flag);
      
    end
    
    function fail = SetRawMotorValues(s,powervec,modecellstr,...
        reset_timeout_flag,answer_flag)
      % Set Raw Motor Values
      %   This allows you to take over one or both of the motor output
      %   values, instead of having the stabilization system control them.
      %   Each motor (left and right) requires a mode (see below) and a
      %   power value from 0-1 representing a fraction of available motor
      %   power. This command will disable stabilization if both modes
      %   aren't 'ignore' so you'll need to re-enable it with
      %   SetStabilization once you're done.
      %
      %   Inputs:
      %     powervec
      %       numerical 2-vector with elements in the range [0,1]
      %       powervec = [left-motor-power,right-motor-power]
      %     modecellstr
      %       2 element cell array of strings specifying the motor modes
      %       modecellstr = {'left-mode-string','right-mode-string'}
      %       mode strings can be: off, forward, reverse, brake, ignore
      
      % handle inputs and default values
      if nargin < 2
        % must supply power
        return;
      end
      if nargin < 3 || isempty(modecellstr)
        % default value for modecellstr
        modecellstr = {'forward','forward'};
      end
      if nargin < 4
        reset_timeout_flag = [];
      end
      if nargin < 5
        answer_flag = [];
      end
      
      % check input values
      assert(isvector(powervec)&&(2==length(powervec))&&all(powervec>=0&powervec<=1),...
        'Input ''powervec'' must be a numerical 2-vector with elements in [0,1].');
      assert(isvector(modecellstr)&&(2==length(modecellstr))&&iscellstr(modecellstr),...
        'Input ''modecellstr'' must be a 2 element cell array of strings.');
      
      pwr = uint8(round(255*powervec));
      
      % init new mode variable to store the enumerated constant values of
      % the API to NaN. Then attempt to assign numerical constants based on
      % the mode strings provided by user. invalid strings allow a nan to
      % pass through.
      md = [nan,nan];
      for ii=1:length(md)
        switch modecellstr{ii}
          % TODO move constants to alias in SpheroCoreConstants
          case 'off'
            md(ii) = 0;
          case 'forward'
            md(ii) = 1;
          case 'reverse'
            md(ii) = 2;
          case 'brake'
            md(ii) = 3;
          case 'ignore'
            md(ii) = 4;
        end
      end
      
      % check for existence of nan to indicate invalid mode string supplied
      % by caller
      assert(all(~isnan(md)),...
        'Invalid mode string. Valid entries are: ''off'', ''forward'', ''reverse'', ''brake'', ''ignore''.');
      
      % put power and mode into left and right scalar vars for readability
      pl = pwr(1);
      pr = pwr(2);
      ml = md(1);
      mr = md(2);
      
      did = s.DID_SPHERO;
      cid = s.CMD_SET_RAW_MOTORS;
      data = [ml,pl,mr,pr];
      
      fail = s.WriteClientCommandPacket(did,cid,data,...
        reset_timeout_flag,answer_flag);
      
    end
    
    function fail = SetMotionTimeout(s,time,...
        reset_timeout_flag,answer_flag)
      % SetMotionTimeout  Set command activity timeout on motion
      %   This sets the ultimate timeout for the last motion command to
      %   keep Sphero from rolling away in the case of a crashed (or
      %   paused) client app. The time parameter is expressed in seconds
      %   and defaults to 2 upon wake-up.
      %
      %   If the control system is enabled, the timeout triggers a stop
      %   otherwise it commands zero PWM to both motors. This "termination
      %   behavior" is inhibited if a macro is running with the flag
      %   MF_EXCLUSIVE_DRV set, or an orbBasic program is executing with a
      %   similar flag, BF_EXCLUSIVE_DRV.
      %
      %   Note that you must enable this action by setting System Option
      %   Flag #4.
      
      if nargin < 2
        return;
      end
      if nargin < 3
        reset_timeout_flag = [];
      end
      if nargin < 4
        answer_flag = [];
      end
      
      if time < 0 || time > (2^16-1)/1000
        return;
      end
      
      time  = time*1000;
      
      time_arr = s.ByteArrayFromInteger(time,'uint16');
      
      did = s.DID_SPHERO;
      cid = s.CMD_SET_MOTION_TO;
      data = time_arr;
      
      fail = s.WriteClientCommandPacket(did,cid,data,...
        reset_timeout_flag,answer_flag);
      
    end
    %{
    function SetPermanentOptionFlags(s,)
      % Set Permanent Option Flags
       
      did = s.DID_SPHERO;
      cid = s.CMD_;
      data = ;
      
      s.WriteClientCommandPacket(did,cid,data);
  
    end
    
    function GetPermanentOptionFlags(s,)
      % Get Permanent Option Flags
       
      did = s.DID_SPHERO;
      cid = s.CMD_;
      data = ;
      
      s.WriteClientCommandPacket(did,cid,data);
  
    end
    
    function SetTemporaryOptionFlags(s,)
      % Set Temporary Option Flags
       
      did = s.DID_SPHERO;
      cid = s.CMD_;
      data = ;
      
      s.WriteClientCommandPacket(did,cid,data);
  
    end
    
    function GetTemporaryOptionFlags(s,)
      % Get Temporary Option Flags
       
      did = s.DID_SPHERO;
      cid = s.CMD_;
      data = ;
      
      s.WriteClientCommandPacket(did,cid,data);
  
    end
    
    function GetConfigurationBlock(s,)
      % Get Configuration Block
       
      did = s.DID_SPHERO;
      cid = s.CMD_;
      data = ;
      
      s.WriteClientCommandPacket(did,cid,data);
  
    end
    
    function SetSSBModifierBlock(s,)
      % Set SSB Modifier Block
       
      did = s.DID_SPHERO;
      cid = s.CMD_;
      data = ;
      
      s.WriteClientCommandPacket(did,cid,data);
  
    end
    
    function SetDeviceMode(s,)
      % Set Device Mode
       
      did = s.DID_SPHERO;
      cid = s.CMD_;
      data = ;
      
      s.WriteClientCommandPacket(did,cid,data);
  
    end
    
    function SetConfigurationBlock(s,)
      % Set Configuration Block
       
      did = s.DID_SPHERO;
      cid = s.CMD_;
      data = ;
      
      s.WriteClientCommandPacket(did,cid,data);
  
    end
    
    function GetDeviceMode(s,)
      % Get Device Mode
       
      did = s.DID_SPHERO;
      cid = s.CMD_;
      data = ;
      
      s.WriteClientCommandPacket(did,cid,data);
  
    end
    
    function GetSSB(s,)
      % Get SSB
       
      did = s.DID_SPHERO;
      cid = s.CMD_;
      data = ;
      
      s.WriteClientCommandPacket(did,cid,data);
  
    end
    
    function SetSSB(s,)
      % Set SSB
       
      did = s.DID_SPHERO;
      cid = s.CMD_;
      data = ;
      
      s.WriteClientCommandPacket(did,cid,data);
  
    end
    
    function RefillBank(s,)
      % Refill Bank
       
      did = s.DID_SPHERO;
      cid = s.CMD_;
      data = ;
      
      s.WriteClientCommandPacket(did,cid,data);
  
    end
    
    function BuyConsumable(s,)
      % Buy Consumable
       
      did = s.DID_SPHERO;
      cid = s.CMD_;
      data = ;
      
      s.WriteClientCommandPacket(did,cid,data);
  
    end
    
    function UseConsumable(s,)
      % Use Consumable
       
      did = s.DID_SPHERO;
      cid = s.CMD_;
      data = ;
      
      s.WriteClientCommandPacket(did,cid,data);
  
    end
    
    function GrantCores(s,)
      % Grant Cores
       
      did = s.DID_SPHERO;
      cid = s.CMD_;
      data = ;
      
      s.WriteClientCommandPacket(did,cid,data);
  
    end
    
    function AddXP(s,)
      % Add XP
       
      did = s.DID_SPHERO;
      cid = s.CMD_;
      data = ;
      
      s.WriteClientCommandPacket(did,cid,data);
  
    end
    
    function LevelUpAttribute(s,)
      % Level Up Attribute
       
      did = s.DID_SPHERO;
      cid = s.CMD_;
      data = ;
      
      s.WriteClientCommandPacket(did,cid,data);
  
    end
    
    function GetPasswordSeed(s,)
      % Get Password Seed
       
      did = s.DID_SPHERO;
      cid = s.CMD_;
      data = ;
      
      s.WriteClientCommandPacket(did,cid,data);
  
    end
    
    function EnableSSBAsyncMessages(s,)
      % Enable SSB Async Messages
       
      did = s.DID_SPHERO;
      cid = s.CMD_;
      data = ;
      
      s.WriteClientCommandPacket(did,cid,data);
  
    end
    
    function RunMacro(s,)
      % Run Macro
       
      did = s.DID_SPHERO;
      cid = s.CMD_;
      data = ;
      
      s.WriteClientCommandPacket(did,cid,data);
  
    end
    
    function SaveTemporaryMacro(s,)
      % Save Temporary Macro
       
      did = s.DID_SPHERO;
      cid = s.CMD_;
      data = ;
      
      s.WriteClientCommandPacket(did,cid,data);
  
    end
    
    function SaveMacro(s,)
      % Save Macro
       
      did = s.DID_SPHERO;
      cid = s.CMD_;
      data = ;
      
      s.WriteClientCommandPacket(did,cid,data);
  
    end
    
    function ReinitMacroExecutive(s,)
      % Reinit Macro Executive
       
      did = s.DID_SPHERO;
      cid = s.CMD_;
      data = ;
      
      s.WriteClientCommandPacket(did,cid,data);
  
    end
    
    function AbortMacro(s,)
      % Abort Macro
       
      did = s.DID_SPHERO;
      cid = s.CMD_;
      data = ;
      
      s.WriteClientCommandPacket(did,cid,data);
  
    end
    
    function GetMacroStatus(s,)
      % Get Macro Status
       
      did = s.DID_SPHERO;
      cid = s.CMD_;
      data = ;
      
      s.WriteClientCommandPacket(did,cid,data);
  
    end
    
    function SetMacroParameter(s,)
      % Set Macro Parameter
       
      did = s.DID_SPHERO;
      cid = s.CMD_;
      data = ;
      
      s.WriteClientCommandPacket(did,cid,data);
  
    end
    
    function AppendMacroChunk(s,)
      % Append Macro Chunk
       
      did = s.DID_SPHERO;
      cid = s.CMD_;
      data = ;
      
      s.WriteClientCommandPacket(did,cid,data);
  
    end
    
    function EraseorbBasicStorage(s,)
      % Erase orbBasic Storage
       
      did = s.DID_SPHERO;
      cid = s.CMD_;
      data = ;
      
      s.WriteClientCommandPacket(did,cid,data);
  
    end
    
    function AppendorbBasicFragment(s,)
      % Append orbBasic Fragment
       
      did = s.DID_SPHERO;
      cid = s.CMD_;
      data = ;
      
      s.WriteClientCommandPacket(did,cid,data);
  
    end
    
    function ExecuteorbBasicProgram(s,)
      % Execute orbBasic Program
       
      did = s.DID_SPHERO;
      cid = s.CMD_;
      data = ;
      
      s.WriteClientCommandPacket(did,cid,data);
  
    end
    
    function AbortorbBasicProgram(s,)
      % Abort orbBasic Program
       
      did = s.DID_SPHERO;
      cid = s.CMD_;
      data = ;
      
      s.WriteClientCommandPacket(did,cid,data);
  
    end
    
    function SubmitValuetoInputStatement(s,)
      % Submit Value to Input Statement
       
      did = s.DID_SPHERO;
      cid = s.CMD_;
      data = ;
      
      s.WriteClientCommandPacket(did,cid,data);
  
    end
    
    function CommitRAMProgramtoFlash(s,)
      % Commit RAM Program to Flash
       
      did = s.DID_SPHERO;
      cid = s.CMD_;
      data = ;
      
      s.WriteClientCommandPacket(did,cid,data);
  
    end
    %}
  end
  
  methods (Static=true,Access=protected)
    
    function out = AssertUserCallbackFcn(func,str)
      assert( (isa(func,'function_handle')&&(2==nargin(func))) || isempty(func),...
        'Property ''%s'' must be a function handle or the empty matrix.',str);
      out = func;
    end
    
    function InvokeUserCallbackFcn(func,src,evt,str)
      % InvokeUserCallbackFcn  invokes callback
      if isempty(func), return; end % fall through if no callback
      try
        func(src,evt);
      catch err
        warning('Error in ''%s'':\n\t%s',str,err.message);
      end
    end
    
    function print_level2diagnostics(data)
      
      fprintf('LEVEL 2 DIAGNOSTICS:\n\n');
      fprintf('%-20s | %-10s | %-20s\n',...
        'NAME','VALUE','DESCRIPTION');
      
      % 00h RecVer Record version code – the following definition is for 01h
      % 02h <empty> Reserved
      
      % 03h Rx_Good Good packets received (unsigned 32-bit value)
      fprintf('%20s | % 10d | %20s\n',...
        'Rx_Good',...
        s.IntegerFromByteArray(data(3+(1:4)),'uint32'),...
        'Good packets received');
      
      % 07h Rx_Bad_DID Packets with a bad Device ID (unsigned 32-bit value)
      fprintf('%20s | % 10d | %20s\n',...
        'Rx_Bad_DID',...
        s.IntegerFromByteArray(data(7+(1:4)),'uint32'),...
        'Packets with a bad Device ID');
      
      % 0Bh Rx_Bad_DLEN Packets with a bad data length (unsigned 32-bit value)
      fprintf('%20s | % 10d | %20s\n',...
        'Rx_Bad_DLEN',...
        s.IntegerFromByteArray(data(11+(1:4)),'uint32'),...
        'Packets with a bad data length');
      
      % 0Fh Rx_Bad_CID Packets with a bad Command ID (unsigned 32-bit value)
      fprintf('%20s | % 10d | %20s\n',...
        'Rx_Bad_CID',...
        s.IntegerFromByteArray(data(15+(1:4)),'uint32'),...
        'Packets with a bad Command ID');
      
      % 13h Rx_Bad_CHK Packets with a bad checksum (unsigned 32-bit value)
      fprintf('%20s | % 10d | %20s\n',...
        'Rx_Bad_CHK',...
        s.IntegerFromByteArray(data(19+(1:4)),'uint32'),...
        'Packets with a bad checksum');
      
      % 17h Rx_Buff_Ovr Receive buffer overruns (unsigned 32-bit value)
      fprintf('%20s | % 10d | %20s\n',...
        'Rx_Buff_Ovr',...
        s.IntegerFromByteArray(data(23+(1:4)),'uint32'),...
        'Receive buffer overruns');
      
      % 1Bh Tx_Msgs Messages transmitted (unsigned 32-bit value)
      fprintf('%20s | % 10d | %20s\n',...
        'Tx_Msgs',...
        s.IntegerFromByteArray(data(+(1:4)),'uint32'),...
        'Messages transmitted');
      
      % 1Fh Tx_Buff_Ovr Transmit buffer overruns (unsigned 32-bit value)
      fprintf('%20s | % 10d | %20s\n',...
        'Tx_Buff_Ovr',...
        s.IntegerFromByteArray(data(31+(1:4)),'uint32'),...
        'Transmit buffer overruns');
      
      % 23h LastBootReason Reason for last boot (8-bit value)
      fprintf('%20s | % 10d | %20s\n',...
        'LastBootReason',...
        s.IntegerFromByteArray(data(35+1),'uint8'),...
        'Reason for last boot');
      
      % 24h BootCounters 16 different counts of boot reasons
      for jj=0:15
        fprintf('%20s | % 10d | %20s\n',...
          sprintf('BootCounters(%02d)',jj+1),...
          s.IntegerFromByteArray(data((36+2*jj)+(1:2)),'uint16'),...
          '16 different counts of boot reasons');
      end
      % 44h <empty> Reserved
      % 46h ChargeCount Charge cycles (unsigned 16-bit value)
      fprintf('%20s | % 10d | %20s\n',...
        'ChargeCount',...
        s.IntegerFromByteArray(data(70+(1:2)),'uint16'),...
        'Charge cycles');
      
      % 48h SecondsSinceCharge Awake time in seconds since last charge (unsigned 16-bit value)
      fprintf('%20s | % 10d | %20s\n',...
        'SecondsSinceCharge',...
        s.IntegerFromByteArray(data(72+(1:2)),'uint16'),...
        'Awake time in seconds since last charge');
      
      % 4Ah SecondsOn Life awake time in seconds (unsigned 32-bit value)
      fprintf('%20s | % 10d | %20s\n',...
        'SecondsOn',...
        s.IntegerFromByteArray(data(74+(1:4)),'uint32'),...
        'Life awake time in seconds');
      
      % 4Eh DistanceRolled Distance rolled (unsigned 32-bit value)
      fprintf('%20s | % 10d | %20s\n',...
        'DistanceRolled',...
        s.IntegerFromByteArray(data(78+(1:4)),'uint32'),...
        'Distance rolled');
      
      % 52h Sensor Failures Count of I2C bus failures (unsigned 16-bit value)
      fprintf('%20s | % 10d | %20s\n',...
        'SensorFailures',...
        s.IntegerFromByteArray(data(82+(1:2)),'uint16'),...
        'Count of I2C bus failures');
      
      % 54h Gyro Adjust Count Lifetime count of automatic GACs (unsigned 32-bit value)
      fprintf('%20s | % 10d | %20s\n',...
        'GyroAdjustCount',...
        s.IntegerFromByteArray(data(84+(1:4)),'uint32'),...
        'Lifetime count of automatic GACs');
    end
  end
  
end
