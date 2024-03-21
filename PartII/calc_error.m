
n = 8; %- bits
resolution = 360/(2^n)
N = 4;

alpha = 10;
k = (0:1:N-1)
ph_th = 180.*k.*sin(alpha*pi/180)
ph_bfic = ph_th./resolution
ph_code = round(ph_bfic)

ph_p = ph_code.*resolution;
error_ph = ph_th - ph_p
