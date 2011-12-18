function w_out = makeSymetric( w )
%MAKESYMETRIC Summary of this function goes here
%   Detailed explanation goes here

w_size = size(w,1);
for row_i=1:w_size
    for  col_i=1:w_size
        value = w(row_i, col_i);
        if ( value ~= 0)
            sym_value = w( col_i, row_i );
            if (sym_value == 0)
                w( col_i, row_i ) = value;
            end
        end
    end
end

w_out = w;

end

