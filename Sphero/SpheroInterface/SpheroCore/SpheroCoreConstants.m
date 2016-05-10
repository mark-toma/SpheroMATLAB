%%SpheroCoreConstants
% Helper class used to store constants of the Sphero low level API Think of
% this like a header file in C languages. Instead of "#include" we get
% these properties into the namespace of another class by subclassing it.
% For example:
%   classdef MyDerivedClass < MyBaseClass & SpheroConstants
% is analogous to,
%   ...
%   #include <SpheroConstants>
%   class MyDerivedClass: MyBaseClass
%   ...
classdef (HandleCompatible) SpheroCoreConstants
  
  properties (Constant, Hidden)
    % === Device IDs ==========================================================
    DID_CORE       =    0;                                                % 00h
    DID_BOOTLOADER =    1;                                                % 01h
    DID_SPHERO     =    2;                                                % 02h
    % END Device IDs ==========================================================
    
    
    % === Core Commands =======================================================
    CMD_PING               =    1;                                        % 01h
    CMD_VERSION            =    2;                                        % 02h
    CMD_CONTROL_UART_TX    =    3;                                        % 03h
    CMD_SET_BT_NAME        =   16;                                        % 10h
    CMD_GET_BT_NAME        =   17;                                        % 11h
    CMD_SET_AUTO_RECONNECT =   18;                                        % 12h
    CMD_GET_AUTO_RECONNECT =   19;                                        % 13h
    CMD_GET_PWR_STATE      =   32;                                        % 20h
    CMD_SET_PWR_NOTIFY     =   33;                                        % 21h
    CMD_SLEEP              =   34;                                        % 22h
    GET_POWER_TRIPS        =   35;                                        % 23h
    SET_POWER_TRIPS        =   36;                                        % 24h
    SET_INACTIVE_TIMER     =   37;                                        % 25h
    CMD_GOTO_BL            =   48;                                        % 30h
    CMD_RUN_L1_DIAGS       =   64;                                        % 40h
    CMD_RUN_L2_DIAGS       =   65;                                        % 41h
    CMD_CLEAR_COUNTERS     =   66;                                        % 42h
    CMD_ASSIGN_TIME        =   80;                                        % 50h
    CMD_POLL_TIMES         =   81;                                        % 51h
    % END Core Commands =======================================================
    
    
    % === Bootloader Commands =================================================
    BEGIN_REFLASH         =    2;                                         % 02h
    HERE_IS_PAGE          =    3;                                         % 03h
    LEAVE_BOOTLOADER      =    4;                                         % 04h
    IS_PAGE_BLANK         =    5;                                         % 05h
    CMD_ERASE_USER_CONFIG =    6;                                         % 06h
    % END Bootloader Commands =================================================
    
    
    % === Sphero Commands =====================================================
    CMD_SET_CAL                 =    1;                                   % 01h
    CMD_SET_STABILIZ            =    2;                                   % 02h
    CMD_SET_ROTATION_RATE       =    3;                                  % 06h
    CMD_GET_CHASSIS_ID          =    7;                                   % 07h
    CMD_SELF_LEVEL              =    9;                                   % 09h
    CMD_SET_VDL                 =   10;                                   % 0Ah
    CMD_SET_DATA_STREAMING      =   17;                                   % 11h
    CMD_SET_COLLISION_DET       =   18;                                   % 12h
    CMD_LOCATOR                 =   19;                                   % 13h
    CMD_SET_ACCELERO            =   20;                                   % 14h
    CMD_READ_LOCATOR            =   21;                                   % 15h
    CMD_SET_RGB_LED             =   32;                                   % 20h
    CMD_SET_BACK_LED            =   33;                                   % 21h
    CMD_GET_RGB_LED             =   34;                                   % 22h
    CMD_ROLL                    =   48;                                   % 30h
    CMD_BOOST                   =   49;                                   % 31h
    CMD_MOVE                    =   50;                                   % 32h
    CMD_SET_RAW_MOTORS          =   51;                                   % 33h
    CMD_SET_MOTION_TO           =   52;                                   % 34h
    CMD_SET_OPTIONS_FLAG        =   53;                                   % 35h
    CMD_GET_OPTIONS_FLAG        =   54;                                   % 36h
    CMD_SET_TEMP_OPTIONS_FLAG   =   55;                                   % 37h
    CMD_GET_TEMP_OPTIONS_FLAG   =   56;                                   % 38h
    CMD_GET_CONFIG_BLK          =   64;                                   % 40h
    CMD_SET_SSB_PARAMS          =   65;                                   % 41h
    CMD_SET_DEVICE_MODE         =   66;                                   % 42h
    CMD_SET_CFG_BLOCK           =   67;                                   % 43h
    CMD_GET_DEVICE_MODE         =   68;                                   % 44h
    CMD_GET_SSB                 =   70;                                   % 46h
    CMD_SET_SSB                 =   71;                                   % 47h
    CMD_SSB_REFILL              =   72;                                   % 48h
    CMD_SSB_BUY                 =   73;                                   % 49h
    CMD_SSB_USE_CONSUMEABLE     =   74;                                   % 4Ah
    CMD_SSB_GRANT_CORES         =   75;                                   % 4Bh
    CMD_SSB_ADD_XP              =   76;                                   % 4Ch
    CMD_SSB_LEVEL_UP_ATTR       =   77;                                   % 4Dh
    CMD_GET_PW_SEED             =   78;                                   % 4Eh
    CMD_SSB_ENABLE_ASYNC        =   79;                                   % 4Fh
    CMD_RUN_MACRO               =   80;                                   % 50h
    CMD_SAVE_TEMP_MACRO         =   81;                                   % 51h
    CMD_SAVE_MACRO              =   82;                                   % 52h
    CMD_INIT_MACRO_EXECUTIVE    =   84;                                   % 54h
    CMD_ABORT_MACRO             =   85;                                   % 55h
    CMD_MACRO_STATUS            =   86;                                   % 56h
    CMD_SET_MACRO_PARAM         =   87;                                   % 57h
    CMD_APPEND_TEMP_MACRO_CHUNK =   88;                                   % 58h
    CMD_ERASE_ORBBAS            =   96;                                   % 60h
    CMD_APPEND_FRAG             =   97;                                   % 61h
    CMD_EXEC_ORBBAS             =   98;                                   % 62h
    CMD_ABORT_ORBBAS            =   99;                                   % 63h
    CMD_ANSWER_INPUT            =  100;                                   % 64h
    %CMD_COMMIT_TO_FLASH         =  101;                                   % 65h
    %CMD_COMMIT_TO_FLASH         =  112;                                   % 70h
    % The command COMMIT_TO_FLASH is duplicated in the API document... idk
    % END Sphero Commands =====================================================
    
    
    % === Message Response Codes ==============================================
    ORBOTIX_RSP_CODE_OK           =    0;                                 % 00h
    ORBOTIX_RSP_CODE_EGEN         =    1;                                 % 01h
    ORBOTIX_RSP_CODE_ECHKSUM      =    2;                                 % 02h
    ORBOTIX_RSP_CODE_EFRAG        =    3;                                 % 03h
    ORBOTIX_RSP_CODE_EBAD_CMD     =    4;                                 % 04h
    ORBOTIX_RSP_CODE_EUNSUPP      =    5;                                 % 05h
    ORBOTIX_RSP_CODE_EBAD_MSG     =    6;                                 % 06h
    ORBOTIX_RSP_CODE_EPARAM       =    7;                                 % 07h
    ORBOTIX_RSP_CODE_EEXEC        =    8;                                 % 08h
    ORBOTIX_RSP_CODE_EBAD_DID     =    9;                                 % 09h
    ORBOTIX_RSP_CODE_MEM_BUSY     =   10;                                 % 0Ah
    ORBOTIX_RSP_CODE_BAD_PASSWORD =   11;                                 % 0Bh
    ORBOTIX_RSP_CODE_POWER_NOGOOD =   49;                                 % 31h
    ORBOTIX_RSP_CODE_PAGE_ILLEGAL =   50;                                 % 32h
    ORBOTIX_RSP_CODE_FLASH_FAIL   =   51;                                 % 33h
    ORBOTIX_RSP_CODE_MA_CORRUPT   =   52;                                 % 34h
    ORBOTIX_RSP_CODE_MSG_TIMEOUT  =   53;                                 % 35h
    % END Message Response Codes ==============================================
    
    
    % === Message Response Messages ===========================================
    ORBOTIX_RSP_MSG_OK           = 'Command succeeded';
    ORBOTIX_RSP_MSG_EGEN         = 'General, non-specific error';
    ORBOTIX_RSP_MSG_ECHKSUM      = 'Received checksum failure';
    ORBOTIX_RSP_MSG_EFRAG        = 'Received command fragment';
    ORBOTIX_RSP_MSG_EBAD_CMD     = 'Unknown command ID';
    ORBOTIX_RSP_MSG_EUNSUPP      = 'Command currently unsupported';
    ORBOTIX_RSP_MSG_EBAD_MSG     = 'Bad message format';
    ORBOTIX_RSP_MSG_EPARAM       = 'Parameter value(s) invalid';
    ORBOTIX_RSP_MSG_EEXEC        = 'Failed to execute command';
    ORBOTIX_RSP_MSG_EBAD_DID     = 'Unknown Device ID';
    ORBOTIX_RSP_MSG_MEM_BUSY     = 'Generic RAM access needed but it is busy';
    ORBOTIX_RSP_MSG_BAD_PASSWORD = 'Supplied password incorrect';
    ORBOTIX_RSP_MSG_POWER_NOGOOD = 'Voltage too low for reflash operation';
    ORBOTIX_RSP_MSG_PAGE_ILLEGAL = 'Illegal page number provided';
    ORBOTIX_RSP_MSG_FLASH_FAIL   = 'Page did not reprogram correctly';
    ORBOTIX_RSP_MSG_MA_CORRUPT   = 'Main Application corrupt';
    ORBOTIX_RSP_MSG_MSG_TIMEOUT  = 'Msg state machine timed out';
    % END Message Response Messages ===========================================
    
    
    % === Streaming Data Masks ================================================
    MASK_ACCEL_X_RAW       = 2147483648; % 8000 0000h - accelerometer axis X, raw -2048 to 2047 4mG
    MASK_ACCEL_Y_RAW       = 1073741824; % 4000 0000h - accelerometer axis Y, raw -2048 to 2047 4mG
    MASK_ACCEL_Z_RAW       =  536870912; % 2000 0000h - accelerometer axis Z, raw -2048 to 2047 4mG
    MASK_GYRO_X_RAW        =  268435456; % 1000 0000h - gyro axis X, raw -32768 to 32767 0.068 degrees
    MASK_GYRO_Y_RAW        =  134217728; % 0800 0000h - gyro axis Y, raw -32768 to 32767 0.068 degrees
    MASK_GYRO_Z_RAW        =   67108864; % 0400 0000h - gyro axis Z, raw -32768 to 32767 0.068 degrees
    MASK_MOTOR_RT_EMF_RAW  =    4194304; % 0040 0000h - right motor back EMF, raw -32768 to 32767 22.5 cm
    MASK_MOTOR_LT_EMF_RAW  =    2097152; % 0020 0000h - left motor back EMF, raw -32768 to 32767 22.5 cm
    MASK_MOTOR_LT_PWM_RAW  =    1048576; % 0010 0000h - left motor, PWM, raw -2048 to 2047 duty cycle
    MASK_MOTOR_RT_PWM_RAW  =     524288; % 0008 0000h - right motor, PWM raw -2048 to 2047 duty cycle
    MASK_IMU_PITCH_FILT    =     262144; % 0004 0000h - IMU pitch angle, filtered -179 to 180 degrees
    MASK_IMU_ROLL_FILT     =     131072; % 0002 0000h - IMU roll angle, filtered -179 to 180 degrees
    MASK_IMU_YAW_FILT      =      65536; % 0001 0000h - IMU yaw angle, filtered -179 to 180 degrees
    MASK_ACCEL_X_FILT      =      32768; % 0000 8000h - accelerometer axis X, filtered -32768 to 32767 1/4096 G
    MASK_ACCEL_Y_FILT      =      16384; % 0000 4000h - accelerometer axis Y, filtered -32768 to 32767 1/4096 G
    MASK_ACCEL_Z_FILT      =       8192; % 0000 2000h - accelerometer axis Z, filtered -32768 to 32767 1/4096 G
    MASK_GYRO_X_FILT       =       4096; % 0000 1000h - gyro axis X, filtered -20000 to 20000 0.1 dps
    MASK_GYRO_Y_FILT       =       2048; % 0000 0800h - gyro axis Y, filtered -20000 to 20000 0.1 dps
    MASK_GYRO_Z_FILT       =       1024; % 0000 0400h - gyro axis Z, filtered -20000 to 20000 0.1 dps
    MASK_MOTOR_RT_EMF_FILT =         64; % 0000 0040h - right motor back EMF, filtered -32768 to 32767 22.5 cm
    MASK_MOTOR_LT_EMF_FILT =         32; % 0000 0020h - left motor back EMF, filtered -32768 to 32767 22.5 cm
    
    MASK2_QUAT_Q0          = 2147483648; % 8000 0000h - Quaternion Q0 -10000 to 10000 1/10000 Q
    MASK2_QUAT_Q1          = 1073741824; % 4000 0000h - Quaternion Q1 -10000 to 10000 1/10000 Q
    MASK2_QUAT_Q2          =  536870912; % 2000 0000h - Quaternion Q2 -10000 to 10000 1/10000 Q
    MASK2_QUAT_Q3          =  268435456; % 1000 0000h - Quaternion Q3 -10000 to 10000 1/10000 Q
    MASK2_ODO_X            =  134217728; % 0800 0000h - Odometer X -32768 to 32767 cm
    MASK2_ODO_Y            =   67108864; % 0400 0000h - Odometer Y -32768 to 32767 cm
    MASK2_ACCEL_ONE        =   33554432; % 0200 0000h - AccelOne 0 to 8000 1 mG
    MASK2_VEL_X            =   16777216; % 0100 0000h - Velocity X -32768 to 32767 mm/s
    MASK2_VEL_Y            =    8388608; % 0080 0000h - Velocity Y -32768 to 32767 mm/s
    % === Streaming Data Masks ================================================
    
    % === Streaming Data Units ============================================
    %                                                     % [my units]        (API documented units)
    
    % these are all effed up i think. im resetting them to unity and trying
    % to work out sensible values from experimentation. 
    %   accel_*     static values should result in 1g or 981 cm/s^s
    %   gyro_*      integration about an axis should result in total
    %               rotation angle
    %
     
    ACCEL_RAW_UNITS_PER_LSB       = 0.004; % [g]
    GYRO_RAW_UNITS_PER_LSB        = 0.068; % [deg(/s?)]
    MOTOR_EMF_RAW_UNITS_PER_LSB   = 1;
    MOTOR_PWM_RAW_UNITS_PER_LSB   = 0.00048828; % [%]
    IMU_RPY_UNITS_PER_LSB         = 1; % [deg]
    ACCEL_FILT_UNITS_PER_LSB      = 0.00024414; % [g]
    GYRO_FILT_UNITS_PER_LSB       = 0.1; %[deg/s]
    MOTOR_EMF_FILT_UNITS_PER_LSB  = 1;
    QUAT_UNITS_PER_LSB            = 0.0001; % [number]
    ODO_UNITS_PER_LSB             = 1; % [cm]
    ACCEL_ONE_UNITS_PER_LSB       = 0.01; % [g]
    VEL_UNITS_PER_LSB             = 0.1; % [cm/s]
    
    SOG_UNITS_PER_LSB             = 1;
    
    % END Streaming Data Units ============================================
    
    % === Async id code =
    ID_CODE_POWER_NOTIFICATIONS             =  1; %01h
    ID_CODE_LEVEL_1_DIAGNOSTIC_RESPONSE     =  2; %02h
    ID_CODE_SENSOR_DATA_STREAMING           =  3; % 03h
    ID_CODE_CONFIG_BLOCK_CONTENTS           =  4; %04h
    ID_CODE_PRE_SLEEP_WARNING               =  5; %05h
    ID_CODE_MACRO_MARKERS                   =  6; %06h
    ID_CODE_COLLISION_DETECTED              =  7; %07h
    ID_CODE_ORB_BASIC_PRINT_MESSAGE         =  8; %08h
    ID_CODE_ORB_BASIC_ERROR_MESSAGE_ASCII   =  9; %09h
    ID_CODE_ORB_BASIC_ERROR_MESSAGE_BINARY  = 10; %0Ah
    ID_CODE_SELF_LEVEL_RESULT               = 11; %0Bh
    ID_CODE_GYRO_AXIS_LIMIT_EXCEEDED        = 12; %0Ch
    ID_CODE_SPHEROS_SOUL_DATA               = 13; %0Dh
    ID_CODE_LEVEL_UP_NOTIFICATION           = 14; %0Eh
    ID_CODE_SHIELD_DAMAGE_NOTIFICATION      = 15; %0Fh
    ID_CODE_XP_UPDATE_NOTIFICATION          = 16; %10h
    ID_CODE_BOOST_UPDATE_NOTIFICATION       = 17; %11h

    
    
    
    
    SOP1 = 255;                  % FFh
    SOP2_MASK_BASE = 240;        % F0h 11110000b
    SOP2_MASK_RESERVED = 12;     % 0Ch 00001100b
    SOP2_MASK_RESET_TIMEOUT = 2; % 02h 00000010b
    SOP2_MASK_ANSWER = 1;        % 01h 00000001b
    
    SOP2_RSP = 255;
    SOP2_ASYNC = 254;
    
    NUM_STREAMING_SENSORS = 30;
    NUM_STREAMING_SENSOR_GROUPS = 12;
    
    BT_DEFAULT_REMOTE_NAME = 'Sphero';
    BT_CHANNEL = 1;
    BT_NUM_CONNECTION_ATTEMPTS = 3;
 
    WAIT_FOR_CMD_RSP_DELAY = 0.001;
    WAIT_FOR_CMD_RSP_TIMEOUT = 4;
    
    SPHERO_CONTROL_SYSTEM_RATE = 400; % [Hz]
    
    SECONDS_PER_DAY = 24*60*60;
    
    COL_DET_METHOD_OFF = 0;
    COL_DET_METHOD_1 = 1; % TODO fix these with semantic names
    COL_DET_METHOD_2 = 2;
    COL_DET_METHOD_3 = 3;
    COL_DET_METHOD_4 = 4;
    COL_DET_NUM_BYTES = 16;
    COL_DET_THRESH_DEFAULT = 0.1;
    COL_DET_SPD_DEFAULT = 0.1;
    COL_DET_DEAD_DEFAULT = 0.1; % [s] 0-255 ms
    
    PWR_CHARGING = 1;
    PWR_OK       = 2;
    PWR_LOW      = 3;
    PWR_CRITICAL = 4;
    
    ACCEL_RANGE_2G  = 0;
    ACCEL_RANGE_4G  = 1;
    ACCEL_RANGE_8G  = 2;
    ACCEL_RANGE_16G = 3;
    
    ROLL_STATE_STOP   = 0;
    ROLL_STATE_NORMAL = 1;
    ROLL_STATE_FAST   = 2;
    
    RAW_MOTOR_MODE_OFF     = 0;
    RAW_MOTOR_MODE_FORWARD = 1;
    RAW_MOTOR_MODE_REVERSE = 2;
    RAW_MOTOR_MODE_BRAKE   = 3;
    RAW_MOTOR_MODE_IGNORE  = 4;
  end
  
end