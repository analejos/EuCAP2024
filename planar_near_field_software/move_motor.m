function move_motor(qty)

p=28.12*100;%%28.12 pasos de la reductora *(200/2) pasos del motor (en el manual del motor pone que es de medio paso)
global s1
s1 = serial('COM3', 'BaudRate', 9600);
fopen(s1)

n=qty*8*p;
n=round(n);
if strcmp('horario',sentido)==1
a=strcat(char(2),'X-',num2str(n),char(3));
else 
   a=strcat(char(2),'X+',num2str(n),char(3)); 
end


fprintf(s1,'%s\r\n',a);
resp2 = fscanf(s1)

fclose(s1); 


