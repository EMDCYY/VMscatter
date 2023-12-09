function code_ref = VMscatterRef(code_rank)

% The matrix including all '0' sequence  + code_ref is full rank
code_ref = zeros(code_rank, code_rank-1);
for ii = 1:1:code_rank-1
    code_ref(:,ii) = 2*[ones(code_rank-ii,1); zeros(ii,1)]-1; 
end

end