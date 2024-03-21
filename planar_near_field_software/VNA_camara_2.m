clear;
clc;


%% Conexión con el Field fox

FieldFox = instrfind('Type', 'tcpip', 'RemoteHost', '192.168.1.100', 'RemotePort', 5025, 'Tag', '');

if isempty(FieldFox)
    FieldFox = tcpip('192.168.1.100', 5025);
else
    fclose(FieldFox);
    FieldFox = FieldFox(1);
end

set(FieldFox,'Timeout',30);% ajustar según IFBW y promediado
% set(FieldFox,'Timeout',100); %si filtro de 10 Hz
% set(FieldFox,'Timeout',10);% ajustar según IFBW y promediado

fopen(FieldFox);



%% Configuración del Fieldfox

% Modo analizador
fprintf(FieldFox, 'INST "NA"');

% Configuración de la frecuencia

fprintf(FieldFox, 'FREQ:CENTER 27E9');

fprintf(FieldFox, 'FREQ:SPAN 0');


% S21
fprintf(FieldFox, 'CALC:PAR:DEF S21');

% log mag
fprintf(FieldFox, 'CALC:FORM MLOG');


% Autoscale 

fprintf(FieldFox, 'DISP:WIND:TRAC1:Y:AUTO\n');

% Configuración de la potencia
fprintf(FieldFox, 'SOUR:POW -0.1\n'); %IMP:Como poner hight pa  nuestro analizador

% Puntos de medida
fprintf(FieldFox, 'SWE:POIN 201\n');

% Ancho de banda IF
fprintf(FieldFox, 'BWID 1000\n');

fprintf(FieldFox, 'INIT:CONT 0\n');
fprintf(FieldFox, '*OPC?\n');
fscanf(FieldFox);

% Promediado     
% fprintf(FieldFox,'AVER:MODE POINT'); 
% fprintf(FieldFox,'AVER:COUNt 3'); 

%% Bucle de medidas

    %directory_command = 'MMEM:CDIR "[SDCARD]:\RAD0"';
    directory_command = 'MMEM:CDIR "[INTERNAL]:\"'; %IMP:Probar ma�ana, si creando la carpeta en el usb que sea, no da error
    fprintf(FieldFox, directory_command);

    %single sweep each time

%     disp('Conectar cables y darle a una tecla')
% pause;
    
%     for i=0:0.5:252
    for i=0:1:252  %--- depender� de la travel distance y el step de movimiento
    %for i=251:-0.5:-1        
        %performs one measurement and wait to finish before accepting new
        %commands 
%         fprintf(FieldFox, 'INIT:CONT OFF');
%         fprintf(FieldFox, '*OPC?\n');
%         fscanf(FieldFox);
        fprintf(FieldFox, 'INIT\n');
        fprintf(FieldFox, '*OPC?\n');
        fscanf(FieldFox);

        % Autoscale
        fprintf(FieldFox, 'DISP:WIND:TRAC1:Y:AUTO\n');
%         pause(1);

        %read data
        name_snp = "'" + i + "_30.s1p" + "'";
        command_snp = 'MMEM:STOR:SNP ' + name_snp;
        fprintf(FieldFox, command_snp);
        fprintf(FieldFox, '*OPC?\n');
        fscanf(FieldFox);

        if i ==252
            %saving screenshot
            name_screenshot = "'" + i + "_" + ".png" + "'";
            command_screenshot = 'MMEM:STOR:IMAG ' + name_screenshot;
            fprintf(FieldFox, command_screenshot);
            fprintf(FieldFox, '*OPC?\n');
            fscanf(FieldFox);
        end

        %mover motor lineal
%       mover_motorlineal(0.5,'horario')
        mover_motorlineal_check(1,'horario')  %---- sustituir por mover motor Zaber

         disp("Medida:");
         disp(i);

    end


    disp('Medida finalizada')
    
% Cerramos conexión con el FieldFox
fclose(FieldFox);
delete(FieldFox);
clear FieldFox;

