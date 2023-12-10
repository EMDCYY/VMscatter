function code_ref = VMscatterRef(NumTag)

% The matrix including all '0' sequence  + code_ref is full rank
code_ref = zeros(NumTag, NumTag-1);
for ii = 1:1:NumTag-1
    code_ref(:,ii) = 2*[ones(NumTag-ii,1); zeros(ii,1)]-1; 
end

end