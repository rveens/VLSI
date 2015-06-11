
function [y] = coef_generate_matlab(L)
        % make sure that coefficients sum to 1
        %y = coef_gen(L);
        y = coef_gen(L)/sum(y);

        % quantize and round to nearest integer
        y = round(y*(2^16)); 
             
        % convert to signed int filter coeff
        y = int16(y);
        y = hex(fi(y, 1, 16, 0)); %1 stands for signed, 16 bit out
        
        %y= y(~isspace(y)); % remove spaces
        dlmwrite('coef.txt',y,''); %create file, with no delimiter ''      
end

function [y] = coef_gen(L)
    % generate 4*L coefficients and start at 0 instead of 1 *stupid matlab*
    for n = 1:4*L
            y(n) = lanczos2(((n-1)/L) -2);
    end
end

function y = lanczos2(t)
    if(t <= -2 || t >= 2)
        y = 0;
    else
        y = sinc(t).*sinc(t/2);
    end
end

%%


