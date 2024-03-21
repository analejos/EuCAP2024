clear all;
clc;
close all;

%%-------- Zaber motors
portName = 'COM3';  % Name of the serial port to use.
baudRate = 9600;    % Baud rate the Zaber device is configured to use.
direccionEjeY = 1;  % Address the Zaber device configured to use as Y axis.
direccionEjeX = 2;  % Address the Zaber device configured to use as X axis.

% Note for simplicity this example does minimal error checking.

% Initialize port.
port = serial(portName);
set(port,'BaudRate',baudRate,'DataBits',8,'FlowControl','none','Parity','none', 'StopBits', 1,'Terminator','CR/LF');

set(port, 'Timeout', 0.5)
warning off MATLAB:serial:fgetl:unsuccessfulRead

% Open the port.
fopen(port);

% instantiate BINARY protocol directly
protocol = Zaber.BinaryProtocol(port);

try
    % try initializing the port and read the motors information
    motorEjeX = Zaber.BinaryDevice.initialize(protocol, direccionEjeX);
    fprintf('Device %d is a %s with firmware version %f\n',direccionEjeX,motorEjeX.Name,motorEjeX.FirmwareVersion);
    
    motorEjeY = Zaber.BinaryDevice.initialize(protocol, direccionEjeY);
    fprintf('Device %d is a %s with firmware version %f\n',direccionEjeY,motorEjeY.Name,motorEjeY.FirmwareVersion);

    fprintf('Homing %s...\n', motorEjeX.Name);
    motorEjeX.home();
    motorEjeX.waitforidle(5);

    fprintf('Homing %s...\n', motorEjeY.Name);
    motorEjeY.home();
    motorEjeY.waitforidle(5);

    motorEjeX_Units = motorEjeX.Units.positiontonative(0.001);
    motorEjeY_Units = motorEjeY.Units.positiontonative(0.001);

    motorEjeY.moveabsolute(94*motorEjeY_Units);
    motorEjeY.waitforidle(5);

    catch exception
    % Clean up the port if an error occurs, otherwise it remains locked.
    fclose(port);
    rethrow(exception);
end

%% VNA Fieldfox connection

FieldFox = instrfind('Type', 'tcpip', 'RemoteHost', '192.168.1.100', 'RemotePort', 5025, 'Tag', '');

if isempty(FieldFox)
    FieldFox = tcpip('192.168.1.100', 5025);
else
    fclose(FieldFox);
    FieldFox = FieldFox(1);
end

%Set input and output buffer defualt sizes
set(FieldFox, 'InputBufferSize', 8096);
set(FieldFox, 'OutputBufferSize', 8069);
% Default binary data read is BigEndian resulting in corrupt data.
% Modify return of binary data from default BigEndian to LittleEndian
% via MathWorks SET command
set(FieldFox,'ByteOrder', 'littleEndian')

set(FieldFox,'Timeout',30);    % set according IFBW and averaging
% set(FieldFox,'Timeout',100); % for IFBW = 10 Hz
fopen(FieldFox);

%% VNA Fieldfox configuration

% Analyzer mode
fprintf(FieldFox, 'INST "NA"');

% % fprintf(FieldFox, 'FREQ:CENTER 27.5E9\n');
% % fprintf(FieldFox, 'FREQ:SPAN:ZERO\n');
fprintf(FieldFox, 'FREQ:STAR 27.5E9;STOP 27.5E9\n');

% S21
fprintf(FieldFox, 'CALC:PAR:DEF S21');

% log mag
fprintf(FieldFox, 'CALC:FORM MLOG');

% Autoscale 
fprintf(FieldFox, 'DISP:WIND:TRAC1:Y:AUTO\n');

% Output power configuration
fprintf(FieldFox, 'SOUR:POW -25\n'); %HIGH Power mode for mmwave

% Trace number of points
fprintf(FieldFox, 'SWE:POIN 101\n');

% BWIF
fprintf(FieldFox, 'BWID 1000\n');

% INIT command
fprintf(FieldFox, 'INIT:CONT 0\n');
fprintf(FieldFox, '*OPC?\n');
fscanf(FieldFox,'%1d');
% fscanf(FieldFox);

% Averaging     
% fprintf(FieldFox,'AVER:MODE POINT'); 
% fprintf(FieldFox,'AVER:COUNt 3'); 

%% Measurment loop
directory_command = 'MMEM:CDIR "[INTERNAL]:\"'; %IMP:Probar mañana, si creando la carpeta en el usb que sea, no da error
fprintf(FieldFox, directory_command);

%single sweep each time

antena = "BF_Renesas_5288";   

pause(1)
step = 1;

N_points = 10;
s21_trace = zeros(N_points,2);

for i=0:step:N_points    
        %--- 1º mido en SPAN ZERO 101 puntos - MLOG     
        % log mag 
        fprintf(FieldFox, 'CALC:FORM MLOG');      

        % Sweep 
        disp("measuring...")
        fprintf(FieldFox, 'INIT\n');
        fprintf(FieldFox, '*OPC?\n');
        fscanf(FieldFox,'%1d');
        pause(0.5)

        % Autoscale to visualize the trace
        fprintf(FieldFox, 'DISP:WIND:TRAC1:Y:AUTO\n');
        pause(1);

        %Query FORMATTED data from fieldFox
        % Set data format to real-32 bin block transfer
        fprintf(FieldFox, 'FORM:DATA REAL,32\n');
        fprintf(FieldFox,'CALC:DATA:FDATA?\n');
        myBinData = binblockread(FieldFox,'float');
        % There will be a line feed not read, i.e. hanging. Read it to clear buffer.
        % If you do not read the hanging line feed a -410, "Query Interrupted
        % Error" will occur
        hangLineFeed = fread(FieldFox,1);
        s21_trace(i+1,1) = 10.*log10(mean(10.^(myBinData./10)));        


        % --- 2º mido en SPAN ZERO 101 puntos - PHASE       
        % PHASE 
        fprintf(FieldFox, 'CALC:FORM UPH'); % PHAS

        % Ejecuta la medida    
        fprintf(FieldFox, 'INIT\n');
        fprintf(FieldFox, '*OPC?\n');
        fscanf(FieldFox,'%1d');       

        % Autoscale to visualize the trace
        fprintf(FieldFox, 'DISP:WIND:TRAC1:Y:AUTO\n');
        pause(1);
 
        fprintf(FieldFox, 'FORM:DATA REAL,32\n');
        fprintf(FieldFox,'CALC:DATA:FDATA?\n');
        myBinData = binblockread(FieldFox,'float');
        hangLineFeed = fread(FieldFox,1);
        s21_trace(i+1,2) = mean(myBinData);        

        %move linear motor
        nn = 1*step;
        motorEjeX.moverelative(motorEjeX_Units);
        motorEjeX.waitforidle(0.1);

        disp("Point:");
        disp(i);
        pause(1)
end

disp('Measurement complete!!')

fprintf('Homing %s...\n', motorEjeX.Name);
motorEjeX.home();
motorEjeX.waitforidle(5);

fprintf('Homing %s...\n', motorEjeY.Name);
motorEjeY.home();
motorEjeY.waitforidle(5);

save s21_planar.s1p s21_trace -ASCII;

% Closing connections with Motors and FieldFox
fclose(FieldFox);
delete(FieldFox);
clear FieldFox;

fclose(port);
delete(port);

